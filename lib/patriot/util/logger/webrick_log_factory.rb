require 'rubygems'
require 'webrick'
require 'singleton'
require 'patriot/util/logger/factory'

module Patriot
  module Util
    module Logger
      # a logger factory implementation based on Webrick Logger
      class WebrickLogFactory < Patriot::Util::Logger::Factory
        # configuration key for log file
        LOG_FILE_KEY  = :log_file
        # configuration key for log level
        LOG_LEVEL_KEY = :log_level

        include Singleton

        # @see Patriot::Util::Logger::Factory
        def build(name, config)
          log_file  = get_log_file(config)
          log_level = get_log_level(config)
          logger = WEBrick::BasicLog.new(log_file, log_level)
          return logger
        end
        private :build

        # @param config [Patriot::Util::Config::Base]
        # @return [String] path to the log file
        def get_log_file(config)
          log_file = config.get(LOG_FILE_KEY)
          return log_file
        end
        private :get_log_file

        # get log level from configuration
        # @param config [Patriot::Util::Config::Base]
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
