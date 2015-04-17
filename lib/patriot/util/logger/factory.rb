require 'thread'
module Patriot
  module Util
    module Logger

      # logger factory
      class Factory
        # configuration key for logger factory class
        FACTORY_CLASS_KEY = :log_factory

        # default logger factory class
        DEFAULT_LOGGER_FACTORY_CLASS = 'Patriot::Util::Logger::Log4rFactory'

        # @param name [String] logger name
        # @param config [Patriot::Util::Config::Base] configuration
        # @return [Patriot::Util::Logger::Facade]
        def self.create_logger(name, config)
          klass = get_factory_class_name(config)
          # implentations of logger facotory should include Singleton
          logger = eval(klass).instance.get_logger(name, config)
          return logger
        end

        # @param config [Patriot::Util::Config::Base]
        # @return [String] factory class name
        def self.get_factory_class_name(config)
          return config.get(FACTORY_CLASS_KEY, DEFAULT_LOGGER_FACTORY_CLASS).to_s
        end

        def initialize
          @mutex   = Mutex.new
          @loggers = {}
        end

        # @param name [String] logger name
        # @param config [Patriot::Util::Config::Base] configuration
        # @return [Patriot::Util::Logger::Facade]
        def get_logger(name, config)
          @mutex.synchronize do
            unless @loggers.has_key?(name)
              logger = build(name,config)
              @loggers[name] = Facade.new(logger)
            end
            return @loggers[name]
          end
        end

        # build logger
        # should be overridden in sub-classes
        # @param name [String] logger name
        # @param config [Patriot::Util::Config::Base] configuration
        def build(name, config)
          raise NotImplementedError
        end

      end
    end
  end
end
