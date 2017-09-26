module Patriot
  module Command
    module PostProcessor

      class DiscardOnFail < Patriot::Command::PostProcessor::Base

        declare_post_processor_name :discard_on_fail

        def process_failure(cmd, worker, job_ticket)
          worker.job_store.set_state(Time.now.to_i, [cmd.job_id], Patriot::JobStore::JobState::DISCARDED)
        end

      end
    end
  end
end
