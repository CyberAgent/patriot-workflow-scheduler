module Patriot
  module Tool
    module PatriotCommands
      # upgrade tool
      module Upgrade

        Patriot::Tool::PatriotCommand.class_eval do
          desc 'upgrade',
               'upgrade installation'
          def upgrade(*path_to_gem)
            opts        = symbolize_options(options)
            conf        = {:ignore_plugin => true}
            conf[:path] = opts[:config] if opts.has_key?(:config)
            config      = load_config(conf)
            controller  = Patriot::Controller::PackageController.new(config)
            controller.upgrade(path_to_gem.empty? ? nil : path_to_gem[0])
          end

        end
      end
    end
  end
end

