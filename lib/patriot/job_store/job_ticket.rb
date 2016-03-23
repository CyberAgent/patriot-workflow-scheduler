module Patriot
  module JobStore
    # a ticket to execute a job.
    class JobTicket
      # default attributes
      attr_accessor :job_id, :update_id, :node
      # attributes for offer
      attr_accessor :exec_node, :exec_host, :exec_thread, :execution_id
      # attributes for completion
      attr_accessor :exit_code, :description

      # @param [String] job_id
      # @param [Integer] update_id
      # @param [String] node the name of node on which the job should be executed
      def initialize(job_id, update_id, node=nil)
        raise "job_id should be Symbol but #{job_id} is a #{job_id.class}" unless job_id.is_a?(String)
        @job_id    = job_id
        @update_id = update_id
        @node      = node
      end

      # @return [String] returns string expression of this instance
      def to_s
        node = @node.nil? ? "any" : @node
        string = "job_id: #{job_id}, update_id: #{update_id}, node: #{node}"
        return string
      end

    end
  end
end
