module Patriot
  module JobStore
    module JobState
      DISCARDED = -2
      INIT      = -1
      SUCCEEDED = 0
      WAIT      = 1
      RUNNING   = 2
      SUSPEND   = 3
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

    EXIT_CODE_TO_STATE = {
      Patriot::Command::ExitCode::SUCCEEDED => Patriot::JobStore::JobState::SUCCEEDED,
      Patriot::Command::ExitCode::FAILED    => Patriot::JobStore::JobState::FAILED
    }

    CONFIG_PREFIX = "jobstore"
    ROOT_STORE_ID = "root"

    INITIATOR_JOB_ID = "INITIATOR"
    DEFAULT_PRIORITY=1 

    require 'patriot/job_store/job_ticket'
    require 'patriot/job_store/job'
    require 'patriot/job_store/base'
    require 'patriot/job_store/factory'
    require 'patriot/job_store/in_memory_store'
    require 'patriot/job_store/rdb_job_store'
  end
end
