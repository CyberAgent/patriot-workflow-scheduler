require 'inifile'
module Patriot
  module Util
    module Config
      class IniFileConfig < Patriot::Util::Config::Base

        COMMON_SECTION = 'common'

        def initialize(path, type = nil)
          raise "path in String is expected but #{path.class}" unless path.is_a?(String)
          @path = path
          config = IniFile.load(path)
          raise "#{path} not found" if config.nil?
          @config = {}
          read_section(config, COMMON_SECTION)
          read_section(config, type)
        end

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
