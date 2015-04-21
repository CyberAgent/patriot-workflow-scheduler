require 'rubygems'
require 'log4r'

require 'patriot/util/logger/facade'
require 'patriot/util/logger/factory'
require 'patriot/util/logger/log4r_factory'
require 'patriot/util/logger/webrick_log_factory'

module Patriot
  module Util
    # logger namespace
    module Logger
      include Patriot::Util::Config

      # create logger based on a given configration
      # @param conf [Patriot::Util::Config::Base]
      def create_logger(conf)
        name    = self.class.to_s
        @logger = Patriot::Util::Logger::Factory.create_logger(name, conf)
      end

    end
  end
end
