require 'patriot/util/config/base'
require 'patriot/util/config/inifile_config'

module Patriot
  module Util
    # namespace for configuration files
    module Config
      # the path to default configuration file
      DEFAULT_CONFIG = File.join($home || Dir.pwd, 'config', 'patriot.ini')
      # a configuration parameter key for plugins
      PLUGIN_KEY = "plugins"
      # a configuration parameter key for plugins directory
      PLUGIN_DIR_KEY = "plugins.dir"
      # default plugins directory
      DEFAULT_PLUGIN_DIR = "plugins"
      # plugin directory
      PLUGIN_LIB_DIR = 'lib'
      # plugin initiation script
      PLUGIN_INIT_SCRIPT = 'init.rb'
      # admin user to access remote host
      ADMIN_USER_KEY = 'admin_user'
      # user who runs worker
      WORKER_USER_KEY = 'worker_user'

      # a comma separated list of hosts where workers are running
      WORKER_HOST_KEY = 'worker_hosts'
      # port number used by info server
      INFO_SERVER_PORT_KEY = 'info_server_port'

      # configuratio key for admin user name
      USERNAME_KEY = 'info_server.admin.username'
      # configuratio key for admin password
      PASSWORD_KEY = 'info_server.admin.password'


      # load configuration file
      # @param option [Hash]
      # @option option :path [String] path to configuration file
      # @option option :type [String] load type (differe by tool)
      # @option option :ignore_plugin [Boolean] set true not to load plugins
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

      # load plugins
      # @param conf [Patriot::Util::Config::Base] configuration to load plugins
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
