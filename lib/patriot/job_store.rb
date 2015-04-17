module Patriot
  # namespace for JobStore
  module JobStore
    # state of jobs in JobStore
    module JobState
      # unneeded and discarded (i.e, trash)
      DISCARDED = -2
      # initiating
      INIT      = -1
      # successfully finished
      SUCCEEDED = 0
      # waiting to be executed
      WAIT      = 1
      # running currently
      RUNNING   = 2
      # suspended and not to be executed
      SUSPEND   = 3
      # executed but failed
      FAILED    = 4

      # get name of the state
      # @param [Patriot::JobStore::JobState] state
      # @return[String]
      def name_of(state)
        state = state.to_i
        return case state
          when -2 then "DISCARDED"
          when -1 then "INIT"
          when 0  then "SUCCEEDED"
          when 1  then "WAIT"
          when 2  then "RUNNING"
          when 3  then "SUSPEND"
          when 4  then "FAILED"
          else raise "unknown state #{state}"
        end
      end
      module_function :name_of
    end

    # mapping from exit code to job state
    # @see Patriot::Command::ExitCode
    EXIT_CODE_TO_STATE = {
      Patriot::Command::ExitCode::SUCCEEDED       => Patriot::JobStore::JobState::SUCCEEDED,
      Patriot::Command::ExitCode::FAILURE_SKIPPED => Patriot::JobStore::JobState::SUCCEEDED,
      Patriot::Command::ExitCode::FAILED          => Patriot::JobStore::JobState::FAILED
    }

    # a prefix for configuration key
    CONFIG_PREFIX = "jobstore"
    # root (default) store_id
    ROOT_STORE_ID = "root"

    # the job identifier for initiator (always succeeded)
    # jobs without any required products to be configured to depend on the initiator
    INITIATOR_JOB_ID = "INITIATOR"
    # default job priority
    DEFAULT_PRIORITY=1 

    require 'patriot/job_store/job_ticket'
    require 'patriot/job_store/job'
    require 'patriot/job_store/base'
    require 'patriot/job_store/factory'
    require 'patriot/job_store/in_memory_store'
    require 'patriot/job_store/rdb_job_store'
  end
end
