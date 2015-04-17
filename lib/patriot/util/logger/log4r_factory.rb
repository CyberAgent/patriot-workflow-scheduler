require 'rubygems'
require 'log4r'
require 'log4r/outputter/datefileoutputter'
require 'patriot/util/logger/factory'
require 'singleton'

module Patriot
  module Util
    module Logger
      # a logger factory implementation for Log4r logger
      class Log4rFactory < Patriot::Util::Logger::Factory
        # configuration key for log level
        LOG_LEVEL_KEY  = :log_level
        # default log level
        DEFAULT_LOG_LEVEL = 'DEBUG'
        # configuration key for log format
        FORMAT_KEY     = :log_format
        # default log format
        DEFAULT_LOG_FORMAT = '%m'
        # configuration key for log outputers
        OUTPUTTERS_KEY = :log_outputters
        # configuration prefix for log outputer
        OUTPUTTER_KEY_PREFIX = :log_outputter

        include Singleton

        # @see Patriot::Util::Logger:Factory
        def build(name, config)
          logger  = Log4r::Logger.new(name)
          logger  = set_log_level(logger, config)
          logger  = set_outputters(logger, config)
          return logger
        end
        private :build

        # set log level to the logger
        def set_log_level(logger, config)
          log_level    = get_log_level(config)
          logger.level = log_level
          return logger
        end
        private :set_log_level

        # set outputters to the logger
        def set_outputters(logger, config)
          formatter   = create_formatter(config)
          logger.outputters = get_outputters(config, formatter)
          return logger
        end
        private :set_outputters

        # create formatter based on the configuration
        def create_formatter(config)
          log_format = get_format_config(config)
          formatter  = Log4r::PatternFormatter.new(:pattern => log_format)
          return formatter
        end
        private :set_outputters

        # @private
        def get_log_level(_conf)
          log_level = _conf.get(LOG_LEVEL_KEY, DEFAULT_LOG_LEVEL)
          log_level = eval("Log4r::#{log_level}")
          return log_level
        end
        private :get_log_level

        # @private
        def get_format_config(_conf)
          return _conf.get(FORMAT_KEY, DEFAULT_LOG_FORMAT)
        end
        private :get_format_config

        # @private
        def get_outputters(_conf, _formatter)
          outputters = _conf.get(OUTPUTTERS_KEY, [])
          outputters = [outputters] unless outputters.is_a?(Array)
          return outputters.map{|o| get_outputter(o, _conf, _formatter)}
          return outputters
        end
        private :get_outputters

        # @private
        def get_outputter(outputter_id, _conf, _formatter)
          class_key = [OUTPUTTER_KEY_PREFIX, outputter_id, "class"].join(".") 
          class_name = _conf.get(class_key)
          raise "logger class: #{class_key} is not set" if class_name.nil?
          outputter = nil
          case class_name
          when "Log4r::StdoutOutputter"
            outputter = Log4r::Outputter.stdout
          when "Log4r::StderrOutputter"
            outputter = Log4r::Outputter.stderr
          when "Log4r::DateFileOutputter" 
            dir_key = [OUTPUTTER_KEY_PREFIX, outputter_id, "dir"].join(".") 
            file_key = [OUTPUTTER_KEY_PREFIX, outputter_id, "file"].join(".") 
            outputter = Log4r::DateFileOutputter.new("file", :filename => _conf.get(file_key), :dirname => _conf.get(dir_key))
          else
            raise "unsupported outputter #{klass}"
          end
          # TODO to set outputter-specific formatter 
          outputter.formatter = _formatter
          return outputter
        end
        private :get_outputter

      end
    end
  end
end

