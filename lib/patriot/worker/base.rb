require 'date'
require 'patriot/command'

module Patriot
  module Worker

    def get_pid(config)
      pid_file = get_pid_file(config)
      return nil unless File.exists?(pid_file)
      pid = nil
      File.open(pid_file,'r'){|f| pid = f.read.strip.to_i }
      begin
        Process.getpgid(pid)
      rescue Errno::ESRCH
        @logger.warn("process #{pid} not exist but pid file remains") if @logger
        return nil
      end
      return pid
    end
    module_function :get_pid

    def get_pid_file(config)
      worker_name = config.get('worker_name', Patriot::Worker::DEFAULT_WORKER_NAME)
      return File.join($home, 'run', "patriot-worker_#{worker_name}.pid")
    end
    module_function :get_pid_file

    # @abstract
    # base class for worker implementations
    class Base

      include Patriot::Util::Logger
      include Patriot::Util::Retry
      include Patriot::JobStore::Factory

      attr_accessor :host, :status, :cycle, :job_store, :config
      attr_reader :started_at

      # @param config [Patriot::Util::Config::Base]
      def initialize(config)
        raise "configuration is nil" if config.nil?
        @logger      = create_logger(config)
        @config      = config
        @job_store   = create_jobstore(Patriot::JobStore::ROOT_STORE_ID, @config)
        @host        = `hostname`.chomp
        @cycle       = config.get('fetch_cycle', Patriot::Worker::DEFAULT_FETCH_CYCLE).to_i
        @fetch_limit = config.get('fetch_limit', Patriot::Worker::DEFAULT_FETCH_LIMIT).to_i
        @worker_name = config.get('worker_name', Patriot::Worker::DEFAULT_WORKER_NAME)
        @info_server = Patriot::Worker::InfoServer.new(self,@config)
      end

      # execute a job
      # @param [Patriot::JobStore::JobTicket] job_ticket a ticket of job to be executed
      # @return [Patriot::Command::ExitCode]
      def execute_job(job_ticket)
        job_ticket.exec_host   = @host
        job_ticket.exec_node   = Thread.current[:name]
        begin
          response = @job_store.offer_to_execute(job_ticket)
        rescue Exception => e
          @logger.error e
          return Patriot::Command::ExitCode::FAILED
        end

        # already executed by other node
        return Patriot::Command::ExitCode::SKIPPED if response.nil?

        @logger.info " executing job: #{job_ticket.job_id}"
        command                 = response[:command]
        job_ticket.execution_id = response[:execution_id]
        job_ticket.exit_code    = Patriot::Command::ExitCode::FAILED
        begin
          command.execute
          job_ticket.exit_code  = Patriot::Command::ExitCode::SUCCEEDED
        rescue Exception => e
          @logger.warn " job : #{job_ticket.job_id} failed"
          @logger.warn e
          job_ticket.description = e.to_s
        else
          job_ticket.description = command.description
        ensure
          begin
            execute_with_retry{ @job_store.report_completion_status(job_ticket) }
          rescue Exception => job_store_error
            @logger.error job_store_error
          end
          unless command.post_processors.nil?
            command.post_processors.each do |pp|
              begin
                @logger.info "executing post process by #{pp}"
                pp.process(command, self, job_ticket)
              rescue Exception => post_process_error
                @logger.error "post process by #{pp} failed"
                @logger.error post_process_error
              end
            end
          end
        end
        return job_ticket.exit_code
      end

      # @return [Integer] pid if the worker is running, otherwise nil
      def get_pid
        return Patriot::Worker.get_pid(@config)
      end

      # send a request graceful shutdown to a running worker
      # @return [Boolean] true worker is running and request is sent, otherwise false
      def request_shutdown
        pid = get_pid
        if pid.nil?
          @logger.info("worker #{@worker_name} does not exist")
          return false
        end
        Process.kill(SIGNAL_FOR_GRACEFUL_SHUTDOWN[0], pid.to_i)
        return true
      end

      # main entry point of worker processing
      def start_worker
        return unless get_pid.nil?
        @logger.info "starting worker #{@node}@#{@host}"
        pid_file = Patriot::Worker.get_pid_file(@config)
        File.open(pid_file, 'w') {|f| f.write($$)} # save pid for shutdown
        set_traps
        @info_server.start_server
        @started_at = Time.now
        @logger.info "initiating worker #{@node}@#{@host}"
        init_worker
        @status = Patriot::Worker::Status::ACTIVE
        @logger.info "start worker #{@node}@#{@host}"
        run_worker
        @logger.info "shutting down worker #{@node}@#{@host}"
        stop_worker
        # should be last since worker_admin judge availability from the info_server
        @info_server.shutdown_server
      end


      # should be overrided in sub class
      # This method is for implementation-specific configuration
      def init_worker
        raise NotImplementedError
      end

      # should be overrided in sub class
      # Main loop in which the worker fetches and executes jobs should be implemented here
      def run_worker
        raise NotImplementedError
      end

      # should be overrided in sub class
      # Tasks for tearing down the worker should be implemented here
      def stop_worker
        raise NotImplementedError
      end

      def set_traps
        Patriot::Worker::SIGNAL_FOR_GRACEFUL_SHUTDOWN.each do |s|
          Signal.trap(s) do
            @status = Patriot::Worker::Status::SHUTDOWN
          end
        end
        Patriot::Worker::SIGNAL_FOR_THREAD_DUMP.each do |s|
          # TODO may not work on Ruby 2.x
          Signal.trap(s) do
            # TODO output to separated stream
            Thread.list.each do |t|
              @logger.info("Thread #{t[:name]}\n#{t.backtrace.map{|bt| "\t#{bt}"}.join("\n")}")
            end
          end
        end
      end
      private :set_traps

    end
  end
end
