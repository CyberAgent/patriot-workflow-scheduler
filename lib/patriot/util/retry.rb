
module Patriot
  module Util
    module Retry
      # execute block and retry the block 
      # @param retry_config :num_retry the max number of retry, :wait_time retry interval
      # @raise an exception thrown from the block
      # @return return value of the block
      def execute_with_retry(retry_config = {}, &blk)
        retry_config = {:num_retry => 3, :wait_time => 3}.merge(retry_config)
        e = nil
        1.upto(retry_config[:num_retry]) do |i|
          begin
            return yield
          rescue Exception => e
            if @logger
              @logger.error "fail to execute (#{i}) #{blk.to_s}"
              @logger.error e
              $@.each{|m| @logger.error m}
            end
          end 
          sleep retry_config[:wait_time]
        end
        raise e unless e.nil?
      end
      module_function :execute_with_retry
    end
  end
end
