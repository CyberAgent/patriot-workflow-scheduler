module Patriot
  module Util
    module Logger
      # facade class for loggers
      class Facade
        # supported log levels
        LEVELS = [:debug, :info, :warn, :error, :fatal]

        # @param logger [Object] logger hidden in this facade
        def initialize(logger)
          @logger = logger
        end

        LEVELS.each do |lvl|
          define_method(lvl) do |msg|
            if msg.is_a? Exception
              @logger.send(lvl, msg.message)
              msg.backtrace.each{|bt| @logger.send(lvl, bt)}
            else
              @logger.send(lvl, msg)
            end
          end
        end

        # for Rack::CommonLogger
        def write(msg)
          @logger.info(msg)
        end
      end
    end
  end
end

