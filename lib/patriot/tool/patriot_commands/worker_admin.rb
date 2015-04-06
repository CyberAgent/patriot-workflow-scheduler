module Patriot
  module Tool
    module PatriotCommands
      module WorkerAdmin

        Patriot::Tool::PatriotCommand.class_eval do
          desc 'worker_admin [options] [start|stop|restart|sleep|wake|status]',
              'controll remote workers'
          method_option :all,
              :aliases  => '-a',
              :type     => :boolean,
              :default  => false,
              :desc     => 'target all worker hosts'
          method_option :host,
              :aliases  => '-h',
              :type     => :string,
              :desc     => 'target host'
          def worker_admin(sub_cmd)
            sub_cmd = "#{sub_cmd}_worker" unless sub_cmd == "status"
            begin
              opts = symbolize_options(options)
              conf        = {:type => 'worker_admin'}
              conf[:path] = opts[:config] if opts.has_key?(:config)
              config      = load_config(conf)
              controller  = Patriot::Controller::WorkerAdminController.new(config)
              result = controller.send(sub_cmd.to_sym, opts)
              print_mtd ="print_#{sub_cmd}".to_sym
              self.send(print_mtd, result, opts) if self.respond_to?(print_mtd)
            rescue => e
              puts e
              raise e
            end
          end

          no_commands do 
            def print_status(result, opts)
              statuses = {}
              unless opts[:all]
                raise "illegal response #{result} from #{opts[:host]}" unless result.size == 1
                result[opts[:host]] = result.delete(result.keys.first)
              end
              result.each do |s,r|
                if r.nil?
                  statuses[s] = 'HALT'
                else
                  r = JSON.parse(r)
                  raise "illegal response #{r} from #{s}" unless r.size == 1
                  statuses[s] = r.values[0].nil? ? 'HALT' : r.values[0]
                end
              end
              puts JSON.generate(statuses)
            end
          end

        end
      end
    end
  end
end
