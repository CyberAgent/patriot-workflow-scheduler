require 'rubygems'
require 'log4r'

require 'patriot/util/logger/facade'
require 'patriot/util/logger/factory'
require 'patriot/util/logger/log4r_factory'
require 'patriot/util/logger/webrick_log_factory'

module Patriot
  module Util
    module Logger
      include Patriot::Util::Config

      def create_logger(conf)
        name    = self.class.to_s
        @logger = Patriot::Util::Logger::Factory.create_logger(name, conf)
      end

    end
  end
end
