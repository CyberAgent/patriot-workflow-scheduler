require 'init_test'

describe Patriot::Command::PostProcessor::StateCallBack do

  include JobStoreMatcher
  include Patriot::Command::Parser


  before :all do
    @dt = '2015-08-01'
    @config = config_for_test
    @worker = Patriot::Worker::Base.new(@config)
    @cmds = Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
  sh{
    state_callback 'callback_url' => 'http://localhost', 'on' => ['succeeded', 'failed']
    name 'both_success'
    commands 'sh -c "exit 0"'
  }
  sh{
    state_callback 'callback_url' => 'http://localhost', 'on' => ['succeeded', 'failed']
    name 'both_fail'
    commands 'sh -c "exit 1"'
  }
  sh{
    state_callback 'callback_url' => 'http://localhost', 'on' => 'succeeded'
    name 'success_success'
    commands 'sh -c "exit 0"'
  }
  sh{
    state_callback 'callback_url' => 'http://localhost', 'on' => 'succeeded'
    name 'success_fail'
    commands 'sh -c "exit 1"'
  }
  sh{
    state_callback 'callback_url' => 'http://localhost', 'on' => 'failed'
    name 'fail_success'
    commands 'sh -c "exit 0"'
  }
  sh{
    state_callback 'callback_url' => 'http://localhost', 'on' => 'failed'
    name 'fail_fail'
    commands 'sh -c "exit 1"'
  }
  sh{
    state_callback 'callback_url' => 'http://localhost', 'on' => ['succeeded', 'failed']
    name 'callback_error'
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
    expect_any_instance_of(Patriot::Command::PostProcessor::StateCallBack).to receive(:send_callback).with("#{job_ticket.job_id}", "http://localhost", "SUCCEEDED")
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should notify on failure with both setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_both_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::StateCallBack).to receive(:send_callback).with("#{job_ticket.job_id}", "http://localhost", "FAILED")
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should notify on success with success enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_success_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::StateCallBack).to receive(:send_callback).with("#{job_ticket.job_id}", "http://localhost", "SUCCEEDED")
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should not notify on failure with success enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_success_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::StateCallBack).not_to receive(:send_callback)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should not notify on success with failure enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::StateCallBack).not_to receive(:send_callback)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
  end

  it "should notify on failure with failure enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::StateCallBack).to receive(:send_callback).with("#{job_ticket.job_id}", "http://localhost", "FAILED")
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
  end

  it "should not notify on success with an illegal url" do
    expect{
      Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
  sh{
    state_callback 'callback_url' => 'http://@illegal_url', 'on' => ['succeeded', 'failed']
    name 'illegal_url'
    commands 'sh -c "exit 0"'
  }
EOJ
      )
    }.to raise_error(RuntimeError)
  end
end
