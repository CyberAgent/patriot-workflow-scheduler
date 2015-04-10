require 'thread'
module Patriot
  module Util
    module Logger

      class Factory
        FACTORY_CLASS_KEY = :log_factory

        DEFAULT_LOGGER_FACTORY_CLASS = 'Patriot::Util::Logger::Log4rFactory'

        def self.create_logger(name, config)
          klass = get_factory_class_name(config)
          # implentations of logger facotory should include Singleton
          logger = eval(klass).instance.get_logger(name, config)
          return logger
        end

        def self.get_factory_class_name(config)
          return config.get(FACTORY_CLASS_KEY, DEFAULT_LOGGER_FACTORY_CLASS).to_s
        end

        def initialize
          @mutex   = Mutex.new
          @loggers = {}
        end

        def get_logger(name, config)
          @mutex.synchronize do
            unless @loggers.has_key?(name)
              logger = build(name,config)
              @loggers[name] = Facade.new(logger)
            end
            return @loggers[name]
          end
        end

        def build(name, config)
          raise NotImplementedError
        end

      end
    end
  end
end
