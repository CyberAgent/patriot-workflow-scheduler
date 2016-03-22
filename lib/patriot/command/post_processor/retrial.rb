module Patriot
  module Command
    module PostProcessor
      class Retrial < Patriot::Command::PostProcessor::Base

        COUNT_PROP_KEY    = :count
        INTERVAL_PROP_KEY = :interval

        declare_post_processor_name :retrial

        def validate_props(props)
          raise "#{COUNT_PROP_KEY} is not specified" unless props.has_key?(COUNT_PROP_KEY)
          raise "#{INTERVAL_PROP_KEY} is not specified" unless props.has_key?(INTERVAL_PROP_KEY)
        end

        def process_failure(cmd, worker, job_ticket)
          found = false
          cmd.post_processors.each do |pp|
            next unless pp.is_a?(Patriot::Command::PostProcessor::Retrial)
            raise "multiple retry processors in #{cmd.job_id}" if found
            found = true
            # count first attempt in
            pp.props[COUNT_PROP_KEY] = pp.props[COUNT_PROP_KEY] - 1
            return if pp.props[COUNT_PROP_KEY] == 0
            cmd.start_datetime = Time.now + pp.props[INTERVAL_PROP_KEY]
          end
          job = cmd.to_job
          current_config = worker.job_store.get_job(job.job_id)
          job[Patriot::Command::PRODUCTS_ATTR] = current_config[Patriot::Command::PRODUCTS_ATTR]
          job[Patriot::Command::REQUISITES_ATTR] = current_config[Patriot::Command::REQUISITES_ATTR]
          job[Patriot::Command::STATE_ATTR] = Patriot::JobStore::JobState::WAIT
          worker.job_store.register(Time.now.to_i, [job])
        end

      end
    end
  end
end


