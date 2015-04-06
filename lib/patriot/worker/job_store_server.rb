require 'thread'
require 'monitor'

module Patriot
  module Worker
    class JobStoreServer < Base

      def build_infoserver
        return Patriot::Worker::InfoServer.new(self,@config)
      end

      def init_worker
      end

      def run_worker
        while(@status != Patriot::Worker::Status::SHUTDOWN)
          sleep @cycle
        end
      end

      def stop_worker
        @logger.info "terminated"
      end

    end
  end
end
