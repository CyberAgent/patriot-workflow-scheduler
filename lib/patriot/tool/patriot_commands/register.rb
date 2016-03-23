module Patriot
  module Tool
    module PatriotCommands
      # register jobs to JobStore
      module Register

        Patriot::Tool::PatriotCommand.class_eval do
          desc 'register [OPTIONS] yyyy-mm-dd[,yyyy-mm-dd] path [path file ...]', 'register jobs'
          method_option :filter,
              :aliases  => '-f',
              :type     => :string,
              :desc     => 'regular expression for Ruby'
          method_option :debug,
              :aliases  => '-d',
              :type     => :boolean,
              :default  => false,
              :desc     => 'debug mode flag'
          method_option :priority,
              :aliases  => '-p',
              :type     => :numeric,
              :desc     => 'job priority'
          method_option :state,
              :aliases  => '-s',
              :type     => :numeric,
              :desc     => 'register as specified state'
          method_option :keep_state,
              :type     => :boolean,
              :default  => false,
              :desc     => "don't change current state of jobs (only change definition)"
          method_option :retry_dep,
              :type     => :boolean,
              :desc     =>  'set states of dependent jobs to WAIT'
          method_option :update_id,
              :type     => :numeric,
              :default  => Time.now.to_i,
              :desc     => 'default value is current unixtime (default value is Time.now.to_i)'
          def register(date, *paths)
            begin
              # set config/options
              opts        = symbolize_options(options)
              conf        = {:type => 'register'}
              conf[:path] = opts[:config] if opts.has_key?(:config)
              config      = load_config(conf)
              opts        = {:update_id      => Time.now.to_i,
                             :store_id       => Patriot::JobStore::ROOT_STORE_ID,
                             :retry_interval => 300,
                             :retry_limite   => 10}.merge(opts)
              if opts[:keep_state]
                opts[:state] = nil
                opts[:update_id] = nil
              end
              job_store = Patriot::JobStore::Factory.create_jobstore(opts[:store_id], config)
              parser  = Patriot::Tool::BatchParser.new(config)
              jobs    = []
              parser.process(date, paths, opts) do |cmd|
                job = cmd.to_job
                job[Patriot::Command::PRIORITY_ATTR] = opts[:priority] if opts.has_key?(:priority)
                job[Patriot::Command::STATE_ATTR] = opts[:state] if opts.has_key?(:state)
                jobs << job
              end
              return if opts[:debug]
              job_store.register(opts[:update_id], jobs)
              if opts[:retry_dep]
                job_store.process_subsequent(jobs.map(&:job_id)) do |job_store, jobs|
                  job_store.set_state(opts[:update_id], jobs.map(&:job_id), Patriot::JobStore::JobState::WAIT)
                end
              end
            rescue => e
              puts e
              $@.each{|m| puts m}
              raise e.message
            end
          end

        end
      end
    end
  end
end
