require 'patriot/util/config/base'
require 'patriot/util/config/inifile_config'

module Patriot
  module Util
    module Config
      DEFAULT_CONFIG = File.join($home || Dir.pwd, 'config', 'patriot.ini')
      PLUGIN_KEY = "plugins"
      PLUGIN_DIR_KEY = "plugins.dir"
      DEFAULT_PLUGIN_DIR = "plugins"
      PLUGIN_LIB_DIR = 'lib' 
      PLUGIN_INIT_SCRIPT = 'init.rb'

      def load_config(option = {})
        option = {:path => DEFAULT_CONFIG, 
                  :type => nil, 
                  :ignore_plugin => false }.merge(option)
        conf = nil
        case File.extname(option[:path])
        when '.ini'
          conf = Patriot::Util::Config::IniFileConfig.new(option[:path], option[:type])
        else
          raise "unsupported config file name: #{conf[:path]}"
        end
        load_plugins(conf) unless option[:ignore_plugin]
        return conf
      end

      def load_plugins(conf)
        plugins = conf.get(PLUGIN_KEY)
        return conf if plugins.nil?
        plugins = [plugins] unless plugins.is_a?(Array)
        plugin_dir = conf.get(PLUGIN_DIR_KEY, DEFAULT_PLUGIN_DIR)
        plugins.each do |plugin|
          path = File.join($home, plugin_dir, plugin)
          init_script = File.join(path, PLUGIN_INIT_SCRIPT)
          raise "Failed to load #{plugin}: #{init_script} does not exist" unless File.file?(init_script)
          $: << File.join(path, PLUGIN_LIB_DIR)
          require init_script
        end
      end
    end
  end
end
