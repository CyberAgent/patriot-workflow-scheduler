module Patriot
  module Tool
    module PatriotCommands
      # a tool to start/stop a worker
      module Worker

        Patriot::Tool::PatriotCommand.class_eval do
          desc 'worker [options] [start|stop]',
               'controll worker'
          method_option :foreground,
              :type     => :boolean,
              :default  => false,
              :desc     => 'run as a foreground job'
          def worker(sub_cmd)
            opts = symbolize_options(options)
            conf        = {:type => 'worker'}
            conf[:path] = opts[:config] if opts.has_key?(:config)
            return if sub_cmd == 'start' && !bootable?(conf)
            Process.daemon unless opts[:foreground]
            config = load_config(conf)
            logger = Patriot::Util::Logger::Factory.create_logger(self.class.to_s, config)
            begin
              worker_cls  = config.get("worker_class", "Patriot::Worker::MultiNodeWorker")
              worker      = eval(worker_cls).new(config)
              case sub_cmd
              when "start"
                worker.start_worker
              when "stop"
                worker.request_shutdown
              else
                raise "unknown sub command #{sub_cmd}"
              end
            rescue Exception => e
              logger.error(e)
              raise e
            end
          end

          no_tasks do
            # check resources and judge whether this worker is bootable
            # @return true if this worker is bootable,
            #         false if the worker has been already running,
            #         otherwize raise error
            def bootable?(conf)
              conf = conf.merge(:ignore_plugin => false)
              config = load_config(conf)
              pid = Patriot::Worker.get_pid(config)
              unless pid.nil?
                puts "worker running as #{pid}, stop it first"
                return false
              end
              logger = Patriot::Util::Logger::Factory.create_logger(self.class.to_s, config)
              pid_file = Patriot::Worker.get_pid_file(config)
              # check log dir permission by writing a log message
              logger.info("checking whether this worker is bootable")
              raise "#{pid_file} is not writable" unless writable_or_creatable?(pid_file)
              return true
            end

            def writable_or_creatable?(file)
              file = File.dirname(file) unless File.exist?(file)
              return File.writable?(file)
            end
            private :writable_or_creatable?

          end
        end
      end
    end
  end
end
