require 'inifile'
module Patriot
  module Util
    module Config
      # a configuration implementation definied by the ini-file format
      class IniFileConfig < Patriot::Util::Config::Base

        # common section name
        COMMON_SECTION = 'common'

        # @param path [String] path to a configuration file
        # @param type [String] load type (section name to be loaded)
        def initialize(path, type = nil)
          raise "path in String is expected but #{path.class}" unless path.is_a?(String)
          @path = path
          config = IniFile.load(path)
          raise "#{path} not found" if config.nil?
          @config = {}
          read_section(config, COMMON_SECTION)
          read_section(config, type)
        end

        # @private
        # read configuration from a section
        # @param config [IniFile] ini file configuration
        # @param section [String] section name
        def read_section(config, section)
          sect = config[section]
          return if sect.nil?
          sect.each{|k,v| @config[k.to_sym] = v }
        end
        private :read_section

        # @see Patriot::Util::Config::Base
        def path
          return @path
        end

        # @see Patriot::Util::Config::Base
        def get(name, default=nil)
          v = @config[name.to_sym]
          v = split_value(v)
          return v.nil? ? default : v
        end

        # split configuration value by a delimiter
        # @param value [String] the value to be splitted
        # @param delimiter [String] delimiter for splitting
        def split_value(value, delimiter = ',')
          # don't allow spaces around value
          regexp = Regexp.new("\\s*#{delimiter}\\s*")
          if value.is_a?(String) && value =~ regexp 
            return value.split(regexp)
          else
            return value
          end
        end
        private :split_value

      end
    end
  end
end
