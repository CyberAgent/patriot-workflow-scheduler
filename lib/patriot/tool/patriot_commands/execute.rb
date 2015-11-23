module Patriot
  module Tool
    # namesapce for patriot command line tools
    module PatriotCommands
      # execute PBC directory
      module Execute

        Patriot::Tool::PatriotCommand.class_eval do
          desc 'execute [options] <yyyy-mm-dd[,yyyy-mm-dd]> <files/paths>+',
              'execute patriot jobs directly'
          method_option :filter,
              :aliases  => '-f',
              :type     => :string,
              :desc     => 'regular expression for job_id'
          method_option :debug,
              :aliases  => '-d',
              :type     => :boolean,
              :default  => false,
              :desc     => 'run in debug mode'
          method_option :test,
              :aliases  => '-t',
              :type     => :boolean,
              :default  => false,
              :desc     => 'run in test mode'
          method_option :strict,
              :type     => :boolean,
              :default  => false,
              :desc     => 'run in strict mode (according to dependency)'
          def execute(date, *paths)
            begin
              # set config/options 
              opts = symbolize_options(options)
              conf        = {:type => 'execute'}
              conf[:path] = opts[:config] if opts.has_key?(:config)
              config      = load_config(conf)
              if opts[:debug] && opts[:test]
                message = "invalid option: both of debug and test are specified"
                raise ArgumentError, message
              end

              # parse and process commands
              parser = Patriot::Tool::BatchParser.new(config)
              commands = parser.process(date, paths, opts)
              if opts[:strict]
                job_store = create_job_store_with_commands(commands, config)
                until (executables = job_store.get_job_tickets(nil,nil)).empty?
                  executables.each do |job_ticket|
                    cmd = job_store.offer_to_execute(job_ticket)
                    execute_command(cmd[:command], opts)
                    job_ticket.exit_code = Patriot::Command::ExitCode::SUCCEEDED
                    job_store.report_completion_status(job_ticket)
                  end
                end
              else
                commands.each{|cmd| execute_command(cmd, opts)}
              end
            rescue => e
              puts e.message
              $@.each {|message| puts message}
              raise e
            end
          end

          no_tasks do
            def create_job_store_with_commands(commands, config)
              job_store = Patriot::JobStore::InMemoryStore.new(Patriot::JobStore::ROOT_STORE_ID, config)
              # ignore products not defined here
              products = commands.map{|cmd| cmd['products']}.flatten.compact
              jobs = commands.map do |cmd|
                cmd.instance_variable_set(:@state, Patriot::JobStore::JobState::INIT)
                cmd['requisites'].delete_if{|ref| !products.include?(ref)}
                cmd.to_job
              end
              job_store.register(Time.now.to_i, jobs)
              return job_store
            end

            def execute_command(command, opts = {})
              puts "executing #{command.job_id}"
              if opts[:debug]
                puts command.description
                return
              end
              command.test_mode = true if opts[:test]
              command.execute
            end
          end
        end
      end
    end
  end
end
