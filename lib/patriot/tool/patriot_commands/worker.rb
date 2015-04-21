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
            Process.daemon unless opts[:foreground]
            config      = load_config(conf)
            worker_cls  = config.get("worker_class", "Patriot::Worker::MultiNodeWorker")
            worker      = eval(worker_cls).new(config)
            case sub_cmd
            when "start"
              then worker.start_worker
            when "stop"
              then worker.request_shutdown
            else
              raise "unknown sub command #{sub_cmd}"
            end
          end
        end
      end
    end
  end
end
