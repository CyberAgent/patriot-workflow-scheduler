require 'init_test'

describe Patriot::Command::PostProcessor::SlackNotification do
  include JobStoreMatcher
  include Patriot::Command::Parser

  before :all do
    @dt = '2015-08-01'
    @config = config_for_test
    @worker = Patriot::Worker::Base.new(@config)
    @url = 'https://localhost'
    @cmds = Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: ['succeeded', 'failed']
    name 'both_success'
    commands 'sh -c "exit 0"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: ['succeeded', 'failed']
    name 'both_fail'
    commands 'sh -c "exit 1"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: 'succeeded'
    name 'success_success'
    commands 'sh -c "exit 0"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: 'succeeded'
    name 'success_fail'
    commands 'sh -c "exit 1"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: 'failed'
    name 'fail_success'
    commands 'sh -c "exit 0"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: 'failed'
    name 'fail_fail'
    commands 'sh -c "exit 1"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: 'failed'
    retrial 'count' => 2, 'interval' => 2
    name 'fail_fail_with_retry_2over'
    commands 'sh -c "exit 1"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: 'failed'
    retrial 'count' => 1, 'interval' => 2
    name 'fail_fail_with_last_retry'
    commands 'sh -c "exit 1"'
  }
  sh {
    slack_notification api_key: 'test', channel: 'ch', username: 'user', on: 'succeeded'
    retrial 'count' => 2, 'interval' => 2
    name 'success_success_with_retry_2over'
    commands 'sh -c "exit 0"'
  }
  sh {
    slack_notification api_key: 'invalid_api_key', channel: 'ch', username: 'user', on: ['succeeded', 'failed']
    name 'invalid_api_key'
    commands 'sh -c "exit 0"'
  }
EOJ
    )
    @job_store = @worker.instance_variable_get(:@job_store)
    @update_id = Time.now.to_i
    @jobs = @cmds.map(&:to_job)
    @job_store.register(@update_id, @jobs)
  end

  it "should notify on success with both setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_both_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).to receive(:http_request).with(Patriot::JobStore::JobTicket, "SUCCEEDED", @url)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should notify on failure with both setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_both_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).to receive(:http_request).with(Patriot::JobStore::JobTicket, "FAILED", @url)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should notify on success with success enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_success_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).to receive(:http_request).with(Patriot::JobStore::JobTicket, "SUCCEEDED", @url)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should not notify on failure with success enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_success_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).not_to receive(:http_request)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should not notify on success with failure enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).not_to receive(:http_request)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should notify on failure with failure enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).to receive(:http_request).with(Patriot::JobStore::JobTicket, "FAILED", @url)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should notify on failure with failure enabled setting with last retry" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_fail_with_retry_2over_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).not_to receive(:http_request)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should notify on failure with failure enabled setting with last retry" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_fail_with_last_retry_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).to receive(:http_request).with(Patriot::JobStore::JobTicket, "FAILED", @url)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should notify on failure with failure enabled setting with last retry" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_success_success_with_retry_2over_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).to receive(:http_request)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should raise error when api_key is not specified" do
    expect{
      Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
        sh {
          slack_notification channel: 'ch', username: 'user', on: ['succeeded', 'failed']
          name 'url_not_set'
          commands 'sh -c "exit 0"'
        }
EOJ
      )
    }.to raise_error(RuntimeError, 'api_key is not specified')
  end

  it "should not send slack message when invalid api key is set" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_invalid_api_key_#{@dt}", @update_id)
    allow(Patriot::Command::PostProcessor::SlackNotification).to receive(:url)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).to receive(:should_notice?)
    expect_any_instance_of(Patriot::Command::PostProcessor::SlackNotification).not_to receive(:http_request)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should raise error when channel is not specified" do
    expect{
      Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
        sh {
          slack_notification api_key: 'test', username: 'user', on: ['succeeded', 'failed']
          name 'channel_not_set'
          commands 'sh -c "exit 0"'
        }
EOJ
      )
    }.to raise_error(RuntimeError, 'channel is not specified')
  end

  it "should raise error when channel is not specified" do
    expect{
      Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
        sh {
          slack_notification api_key: 'test', channel: 'ch', on: ['succeeded', 'failed']
          name 'username_not_set'
          commands 'sh -c "exit 0"'
        }
EOJ
      )
    }.to raise_error(RuntimeError, 'username is not specified')
  end

  it "should raise error when channel is not specified" do
    expect{
      Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
        sh {
          slack_notification api_key: 'test', channel: 'ch', username: 'user'
          name 'on_not_set'
          commands 'sh -c "exit 0"'
        }
EOJ
      )
    }.to raise_error(RuntimeError, 'on is not specified')
  end
end
