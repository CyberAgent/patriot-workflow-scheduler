require 'patriot/util'

module Patriot
  module JobStore
    class Base
      include Patriot::Util::Logger

      # @param [String] store_id identifier of this store
      # @param [Patriot::Util::Config::Base] config configuration of this store
      def initialize(store_id, config)
        raise NotImplementedError
      end

      # register the given jobs with the given update_id
      # @param [Integer] update_id
      # @param [Array] jobs a list of jobs to be registered
      def register(update_id, jobs)
        raise NotImplementedError
      end

      # check whether the command can be stored as a job to this job_store
      # @param [Patriot::Command::Base] command
      # @return [Boolean] true if the command can be converted to a job
      def acceptable?(command)
        raise NotImplementedError
      end

      # get job tickets for jobs which are ready to execute
      # @param [String] host the host name of the client
      # @param [Array] nodes array of nodes on the client
      # @param opts [Hash]
      # @option opts [Integer] :fetch_limit the max number of tickets
      def get_job_tickets(host, nodes, opts = {})
        raise NotImplementedError
      end

      # offer to execute a job specified with a job_ticket
      # If the job is ready to execute, the state of job is set to {Patriot::JobStore::JobState::RUNNING}.
      # A response of this method is a Hash including
      # * :execution_id the identifier of the execution (used to identify history record)
      # * :command an instance of command for the offered job
      # @param [Patriot::JobStore::JobTicket] job_ticket the ticket of the job of which execution is offered.
      # @return [Hash] response for the offer
      def offer_to_execute(job_ticket)
        raise NotImplementedError
      end

      # report completion status a job specified with a job_ticket
      # The state of the job should be changed according to the completion status.
      # @param [Patriot::JobStore::JobTicket] job_ticket the ticket of the job of which completion is reported
      # @return [Boolean] true if the job exists and the state is updated, otherwise false
      def report_completion_status(job_ticket)
        raise NotImplementedError
      end

      # set jobs state
      # @param [Integer] update_id
      # @param [Array] job_ids list of job_ids
      # @param [Integer] new_state new state of the job.
      def set_state(update_id, job_ids, new_state)
        raise NotImplementedError
      end

      # get a job
      # @param [String] job_id
      # @param [Hash] opts
      # @option opts [String] :include_dependency include jobs with 1-hop dependency
      # @return [Patrio::JobStore::Job] in case of include_dependency is true,
      # jobs in dependency set to :consumers/:producers as a hash from job_id to state
      def get(job_id, opts={})
        job = get_job(job_id)
        return if job.nil?
        if opts[:include_dependency] == true
          job['consumers'] = get_consumers(job[Patriot::Command::PRODUCTS_ATTR]) || {}
          job['producers'] = get_producers(job[Patriot::Command::REQUISITES_ATTR]) ||{}
        end
        return job
      end

      # get a job data
      # @param [String] job_id
      # @return [Patriot::JobStore::Job]
      def get_job(job_id)
        raise NotImplementedError
      end

      # get producers of products
      # @param [Array] products a list of product name
      # @param [Hash] opts
      # @option opt [Array] :include_attrs a list of attribute included in results
      # @return [Hash] a hash from product name to producer jobs
      def get_producers(products, opts = {:include_attrs => [Patriot::Command::STATE_ATTR]})
        raise NotImplementedError
      end
  
      # get consumers of products
      # @param [Array] products a list of product name
      # @param [Hash] opts
      # @option opt [Array] :include_attrs a list of attribute included in results
      # @return [Hash] a hash from product name to consumer jobs
      def get_consumers(products, opts = {:include_attrs => [Patriot::Command::STATE_ATTR]})
        raise NotImplementedError
      end

      # get execution histories of the specified job
      # @param [String] job_id
      # @param [Hash] opts
      # @option opts [Integer] :limit a max number of history records (default 1)
      # @option opts [Symbol] :order order of record [:DESC or :ASC, default is :DESC]
      def get_execution_history(job_id, opts = {})
        raise NotImplementedError
      end

      # @param [Patriot::JobStore::JobState] state
      # @param [Hash] opts
      # @option ops [Integer] :limit a max nubmer of jobs fetched at once
      # @option ops [Integer] :offset the number of records skipped before beginning to include to a result
      # @option ops [String] :filter_exp additional condition on job_id in a LIKE expression
      # @return [Array] an array of job_id  which is in the given state
      def find_jobs_by_state(state, opts = {})
        raise NotImplementedError
      end

      # @param [Hash] opts
      # @option [Array<Patriot::JobStore::JobState>] :ignore_states
      # @return [Hash<Patriot::JobStore::JobState, Integer>] a hash from job state to the number of jobs in the state 
      def get_job_size(opts = {})
        raise NotImplementedError
      end

      # delete the job from this job_store
      # @param [String] job_id
      def delete_job(job_id)
        raise NotImplementedError
      end

    end
  end
end
