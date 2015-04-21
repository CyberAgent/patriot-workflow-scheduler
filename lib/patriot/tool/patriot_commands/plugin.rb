module Patriot
  module Tool
    module PatriotCommands
      # manage plugins
      module Plugin

        Patriot::Tool::PatriotCommand.class_eval do
          desc 'plugin [options] install <path to plugin>',
              'manage plugins'
          method_option :force,
              :aliases  => '-f',
              :type     => :boolean,
              :desc     => 'force operation'
          method_option :unpack,
              :type     => :boolean,
              :desc     => 'unpack gem into plugin dir'
          def plugin(sub_cmd, *plugin)
            opts        = symbolize_options(options)
            conf        = {:ignore_plugin => true}
            conf[:path] = opts[:config] if opts.has_key?(:config)
            config      = load_config(conf)
            controller  = Patriot::Controller::PackageController.new(config)
            plugins = []
            if plugin.nil? || plugin.empty?
              plugins = config.get(Patriot::Util::Config::PLUGIN_KEY, plugin)
            else
              plugins = plugin
            end
            sub_cmd = sub_cmd.to_sym
            if sub_cmd == :install
              plugins.each{|name| controller.install_plugin(name, opts) }
            else
              help("plugin")
            end
          end

        end
      end
    end
  end
end
