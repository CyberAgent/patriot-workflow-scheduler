require 'init_test'

describe Patriot::Command::PostProcessor::MailNotification do 

  include JobStoreMatcher
  include Patriot::Command::Parser


  before :all do 
    @dt     = '2015-08-01'
    @config = config_for_test
    @worker = Patriot::Worker::Base.new(@config)
    @cmds   = Patriot::Command::CommandGroup.new(@config).parse(Time.new(2015,8,1), <<'EOJ'
  sh{
    mail_notification 'to' => 'to@test', 'on' => ['succeeded', 'failed']
    name 'both_success'
    commands 'sh -c "exit 0"'
  }
  sh{
    mail_notification 'to' => 'to@test', 'on' => ['succeeded', 'failed']
    name 'both_fail'
    commands 'sh -c "exit 1"'
  }
  sh{
    mail_notification 'to' => 'to@test', 'on' => 'succeeded'
    name 'success_success'
    commands 'sh -c "exit 0"'
  }
  sh{
    mail_notification 'to' => 'to@test', 'on' => 'succeeded'
    name 'success_fail'
    commands 'sh -c "exit 1"'
  }
  sh{
    mail_notification 'to' => 'to@test', 'on' => 'failed'
    name 'fail_success'
    commands 'sh -c "exit 0"'
  }
  sh{
    mail_notification 'to' => 'to@test', 'on' => 'failed'
    name 'fail_fail'
    commands 'sh -c "exit 1"'
  }
EOJ
    )
    @job_store = @worker.instance_variable_get(:@job_store)
    @update_id = Time.now.to_i
    @jobs       = @cmds.map(&:to_job)
    @job_store.register(@update_id, @jobs)
  end

  it "sholud notify on success with both setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_both_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::MailNotification).to receive(:deliver).with("from@test", "to@test", "#{job_ticket.job_id} has been successfully finished", anything)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
    job = @job_store.get_job(job_ticket.job_id)
    expect(job).to be_succeeded_in @job_store
  end

  it "sholud notify on failure with both setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_both_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::MailNotification).to receive(:deliver).with("from@test", "to@test", "#{job_ticket.job_id} has been failed", anything)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
    job = @job_store.get_job(job_ticket.job_id)
    expect(job).to be_failed_in @job_store
  end

  it "sholud notify on success with success enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_success_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::MailNotification).to receive(:deliver).with("from@test", "to@test", "#{job_ticket.job_id} has been successfully finished", anything)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
    job = @job_store.get_job(job_ticket.job_id)
    expect(job).to be_succeeded_in @job_store
  end

  it "sholud not notify on failure with success enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_success_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::MailNotification).not_to receive(:deliver)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
    job = @job_store.get_job(job_ticket.job_id)
    expect(job).to be_failed_in @job_store
  end

  it "sholud not notify on success with failure enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_success_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::MailNotification).not_to receive(:deliver)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::SUCCEEDED
    job = @job_store.get_job(job_ticket.job_id)
    expect(job).to be_succeeded_in @job_store
  end

  it "sholud notify on failure with failure enabled setting" do
    job_ticket = Patriot::JobStore::JobTicket.new("sh_fail_fail_#{@dt}", @update_id)
    expect_any_instance_of(Patriot::Command::PostProcessor::MailNotification).to receive(:deliver).with("from@test", "to@test", "#{job_ticket.job_id} has been failed", anything)
    expect(@worker.execute_job(job_ticket)).to eq Patriot::Command::ExitCode::FAILED
    job = @job_store.get_job(job_ticket.job_id)
    expect(job).to be_failed_in @job_store
  end
end
