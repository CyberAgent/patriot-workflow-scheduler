module Patriot
  module Tool
    module PatriotCommands
      module Validate

        Patriot::Tool::PatriotCommand.class_eval do
          VALIDATE_SAMPLE_DATE = '1999-01-31'
          desc 'validate [OPTIONS] path [path file ...]', 'validate pbc files'
          method_option :stop_on_detection,
              :aliases  => '-s',
              :type     => :boolean,
              :default  => false,
              :desc     => 'stop immediately when invalid config detected'
          method_option :date,
              :type     => :string,
              :desc     => 'date passed to parser'
          def validate(*paths)
            begin
              opts        = symbolize_options(options)
              conf        = {:type => 'validator'}
              conf[:path] = opts[:config] if opts.has_key?(:config)
              config      = load_config(conf)
              # the value of :all is passed to Patriot::Util::Script.get_batch_files(path, opt = {})
              opts = {:all => true, :date => VALIDATE_SAMPLE_DATE}.merge(opts)

              job_store      = Patriot::JobStore::Factory.create_jobstore(Patriot::JobStore::ROOT_STORE_ID, config)
              job_ids        = {}
              invalid_syntax = []
              valid           = true

              parser = Patriot::Tool::BatchParser.new(config)
              parser.process(opts[:date], paths, opts) do |cmd, source|
                unless job_store.acceptable?(cmd.to_job)
                  invalid_syntax << "#{command.job_id} in ${source[:path]}"
                  valid = false
                end
                get_all_job_ids(cmd).each do |jid|
                  if job_ids.has_key?(jid)
                    job_ids[jid] << source[:path]
                    valid = false
                  else
                    job_ids[jid] = [source[:path]]
                  end
                end
                break if opts[:stop_on_detection] && !valid
              end

              unless valid
                unless invalid_syntax.empty?
                  puts "#{invalid_syntax.size} jobs are serialized to invalid syntax:"
                  invalid_syntax.each{|i| puts "\ti" }
                end

                # count dupliates
                dup_cnt = job_ids.values.select{|files| files.size > 1}
                unless dup_cnt == 0
                  puts "#{dup_cnt} duplications are detected:"
                  job_ids.each do |jid, files|
                    next if files.size == 1
                    puts "#{files.size} #{jid} in "
                    files.each{|d| puts "\t#{d} " }
                  end
                end
                raise "invalid batch config is detected"
              end
              puts "no invalid config is detected"
            end
          end

          no_tasks do
            def get_all_job_ids(cmd)
              ids = [cmd.job_id]
              if cmd.is_a?(Patriot::Command::CompositeCommand)
                ids |= cmd.instance_variable_get(:@contained_commands).map{|cc| get_all_job_ids(cc)}.flatten
              end
              return ids
            end
          end
        end
      end
    end
  end
end
