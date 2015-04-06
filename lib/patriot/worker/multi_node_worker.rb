require 'thread'
require 'monitor'

module Patriot
  module Worker

    # a worker implementation which can host multiple node on one process
    class MultiNodeWorker < Base

      include MonitorMixin

      # type of node
      ANY = 'any'
      OWN = 'own' 
      SUPPORTED_TYPES = [ANY,OWN]

      # type of job
      ANY_EXCLUDE_TYPE_OWN = 0
      ONLY_SPECIFIED_NODE  = 1
      UNEXPECTED           = 2

      # @see Patriot::Worker::Base#init_worker
      def init_worker 
        nodes = @config.get('nodes')
        raise "nodes are not configured" if nodes.nil?
        nodes = [nodes] unless nodes.is_a?(Array)
        @nodes = {}
        nodes.each do |n|
          node_config = get_node_config(@config, n)
          raise "node #{n} is not configured" if node_config.nil?
          @nodes[n] = {:queue => Queue.new }.merge(node_config)
        end
      end

      def get_node_config(config, n)
        type    = config.get("node.#{n}.type")
        threads = config.get("node.#{n}.threads")
        raise "the number of threads for node #{n} is not set" if threads.nil?
        raise "unsupported node type: #{n} with #{type} " unless SUPPORTED_TYPES.include?(type)
        return {:type =>  type, :threads => threads.to_i}
      end
      private :get_node_config

      # @see Patriot::Worker::Base#run_worker
      def run_worker
        @threads = []
        # create node threads for job execution
        @nodes.each do |node,conf|
          1.upto(conf[:threads]) do |i| 
            @threads << create_thread(node, i, conf[:queue])
          end
        end
        # start main thread for updating queues
        Thread.current[:name] = 'main'
        while(alive?)
          if @status == Patriot::Worker::Status::ACTIVE
            begin
              job_tickets = @job_store.get_job_tickets(@host, @nodes.keys, {:fetch_limit => @fetch_limit})
              @logger.info "get #{job_tickets.size} jobs"
              update_queue(job_tickets) unless job_tickets.nil?
            rescue => e
              @logger.error e
            end
          end
          sleep @cycle
        end
      end

      def create_thread(node, thread_number, queue)
        Thread.start(queue) do |q|
          Thread.current[:name] = "worker_#{node}_#{thread_number}"
          Thread.current[:node] = node
          begin
            while(@status != Patriot::Worker::Status::SHUTDOWN)
              job_ticket = q.pop
              if job_ticket == :TERM
                @logger.info "terminating"
              else
                @logger.debug "fetch job #{job_ticket.job_id}"
                Thread.current[Patriot::Worker::JOB_ID_IN_EXECUTION] = job_ticket.job_id
                execute_job(job_ticket)
                Thread.current[Patriot::Worker::JOB_ID_IN_EXECUTION] = nil
              end
            end
          rescue Exception => e
            @logger.error e
            raise e, "exception in worker thread" , $@
          ensure
            @logger.info "terminated"
            interrupted_job = Thread.current[Patriot::Worker::JOB_ID_IN_EXECUTION]
            @logger.warn "job: #{interrupted_job} could be interrupted." unless interrupted_job.nil?
          end
        end
      end
      private :create_thread

      # check thread status
      def alive?
        @threads.each do |t|
          if t.status.nil? # thread stopped by some error
            @logger.error "#{t[:name]} : nil " 
            @status = Patriot::Worker::Status::SHUTDOWN
          elsif t.status == false # stopped by signal
            @logger.debug "#{t[:name]} : false "
            @status = Patriot::Worker::Status::SHUTDOWN
          else
            @logger.debug "#{t[:name]} : #{t.status}"
          end
        end
        return @status != Patriot::Worker::Status::SHUTDOWN
      end
      private :alive?

      # update job queues
      def update_queue(job_tickets)
        @nodes.each{|node,conf| conf[:queue].clear }
        job_tickets.each do |job_ticket|
          case type_of_job(job_ticket)
          when ANY_EXCLUDE_TYPE_OWN 
            @nodes.each{|node,conf| conf[:queue].push(job_ticket) unless conf[:type]==OWN }
          when ONLY_SPECIFIED_NODE
            @nodes[job_ticket.node][:queue].push(job_ticket)
          else
            @logger.warn "receive unexpected job #{job_ticket.to_s}"
          end
        end
      end
      private :update_queue

      def type_of_job(job_ticket)
        return ANY_EXCLUDE_TYPE_OWN if job_ticket.node.nil?
        return ONLY_SPECIFIED_NODE if @nodes.has_key?(job_ticket.node)
        return UNEXPECTED;
      end
      private :type_of_job

      # @see Patriot::Worker::Base#run_worker
      def stop_worker
        @status = Patriot::Worker::Status::SHUTDOWN
        @logger.info "terminating worker"
        @nodes.each do |node,conf|
          conf[:queue].clear
          1.upto(conf[:threads]) {|i| conf[:queue].push(:TERM) }
        end
        @threads.each{|t| t.join}
        @logger.info "terminated"
      end

    end
  end
end
