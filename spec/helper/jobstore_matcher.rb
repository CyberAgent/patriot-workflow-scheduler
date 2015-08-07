require 'rubygems'
require 'rspec'

module JobStoreMatcher

  RSpec::Matchers.define :be_waited_in do |job_store|
    match do |job|
      job_store.find_jobs_by_state(Patriot::JobStore::JobState::WAIT).include?(job.job_id)
    end
    failure_message do |job|
      "expected #{Patriot::JobStore::JobState::WAIT} but #{job_store.get_job(job.job_id)[Patriot::Command::STATE_ATTR]}"
    end
  end

  RSpec::Matchers.define :be_succeeded_in do |job_store|
    match do |job|
      job_store.find_jobs_by_state(Patriot::JobStore::JobState::SUCCEEDED).include?(job.job_id)
    end
    failure_message do |job|
      "expected #{Patriot::JobStore::JobState::SUCCEEDED} but #{job_store.get_job(job.job_id)[Patriot::Command::STATE_ATTR]}"
    end
  end

  RSpec::Matchers.define :be_failed_in do |job_store|
    match do |job|
      job_store.find_jobs_by_state(Patriot::JobStore::JobState::FAILED).include?(job.job_id)
    end
    failure_message do |job|
      "expected #{Patriot::JobStore::JobState::FAILED} but #{job_store.get_job(job.job_id)[Patriot::Command::STATE_ATTR]}"
    end
  end

  RSpec::Matchers.define :be_running_in do |job_store|
    match do |job|
      job_store.find_jobs_by_state(Patriot::JobStore::JobState::RUNNING).include?(job.job_id)
    end
    failure_message do |job|
      "expected #{Patriot::JobStore::JobState::RUNNING} but #{job_store.get_job(job.job_id)[Patriot::Command::STATE_ATTR]}"
    end
  end
end

