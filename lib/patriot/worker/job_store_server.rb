require 'thread'
require 'monitor'

module Patriot
  module Worker
    # a worker as info server
    class JobStoreServer < Base

      # @see Patriot::Worker::Base#build_infoserver
      def build_infoserver
        return Patriot::Worker::InfoServer.new(self,@config)
      end

      # @see Patriot::Worker::Base#init_worker
      def init_worker
      end

      # @see Patriot::Worker::Base#run_worker
      def run_worker
        while(@status != Patriot::Worker::Status::SHUTDOWN)
          sleep @cycle
        end
      end

      # @see Patriot::Worker::Base#stop_worker
      def stop_worker
        @logger.info "terminated"
      end

    end
  end
end
