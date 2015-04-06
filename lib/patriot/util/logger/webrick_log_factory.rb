require 'rubygems'
require 'webrick'
require 'singleton'
require 'patriot/util/logger/factory'

module Patriot
  module Util
    module Logger
      class WebrickLogFactory < Patriot::Util::Logger::Factory
        LOG_FILE_KEY  = :log_file
        LOG_LEVEL_KEY = :log_level

        include Singleton

        def build(name, config)
          log_file  = get_log_file(config)
          log_level = get_log_level(config)
          logger = WEBrick::BasicLog.new(log_file, log_level)
          return logger
        end
        private :build

        def get_log_file(config)
          log_file = config.get(LOG_FILE_KEY)
          return log_file
        end
        private :get_log_file

        def get_log_level(config)
          log_level = config.get(LOG_LEVEL_KEY)
          const     = "WEBrick::BasicLog::#{log_level}".to_sym
          return const 
        end
        private :get_log_level

      end
    end
  end
end
