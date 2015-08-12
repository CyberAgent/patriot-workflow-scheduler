require 'init_test'
require 'patriot/tool/patriot_commands/register'

describe Patriot::Tool::PatriotCommands::Register do
  before :all do
    @config = "#{ROOT_PATH}/spec/config/test.ini"
  end

  before :each do
    @job_store = Patriot::JobStore::InMemoryStore.new("root", config_for_test)
    allow(Patriot::JobStore::Factory).to receive(:create_jobstore).and_return(@job_store)
  end
  
  describe "help" do
    it "should show help" do
      args = ['help']
      Patriot::Tool::PatriotCommand.start(args)
    end
  end

  describe "register" do
    it "can execute" do
      args = [
          'register',
          "--config=#{@config}",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh.pbc"
        ]
      expect(@job_store).not_to receive(:retry_dependent)
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(@job_store.get("sh_echo_2013-01-01")['state']).to eq Patriot::JobStore::JobState::WAIT
      expect(@job_store.get("sh_echo_2013-01-01")['priority']).to eq Patriot::JobStore::DEFAULT_PRIORITY
      expect(@job_store.get("sh_echo_2013-01-01").update_id).to be_between(Time.now.to_i - 60, Time.now.to_i)
    end

    it "can debug pbc" do
      args = [
          'register',
          "--config=#{@config}",
          "--debug",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh.pbc"
        ]
      expect(@job_store).not_to receive(:register)
      expect(@job_store).not_to receive(:retry_dependent)
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "can register multiple file" do
      args = [
          'register',
          "--config=#{@config}",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh1.pbc",
          "#{ROOT_PATH}/spec/pbc/sh2.pbc"
        ]
      expect(@job_store).not_to receive(:retry_dependent)
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      job_ids = @job_store.instance_variable_get(:@jobs).keys.map(&:to_s)
      expect(job_ids).to contain_exactly("sh_sh1_2013-01-01", "sh_sh2_2013-01-01")
    end

    it "can register by date range" do
      args = [
          'register',
          "--config=#{@config}",
          '2013-01-01,2013-01-03',
          "#{ROOT_PATH}/spec/pbc/sh.pbc"
        ]
      expect(@job_store).not_to receive(:retry_dependent)
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      job_ids = @job_store.instance_variable_get(:@jobs).keys.map(&:to_s)
      expect(job_ids).to contain_exactly("sh_echo_2013-01-01","sh_echo_2013-01-02","sh_echo_2013-01-03")
    end

    it "can register to retry dependent" do
      args = [
          'register',
          "--config=#{@config}",
          "--state=0",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/consumer.pbc",
          "#{ROOT_PATH}/spec/pbc/producer.pbc"
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      job_ids = @job_store.instance_variable_get(:@jobs).keys.map(&:to_s)
      expect(job_ids).to contain_exactly("sh_producer_2013-01-01", "sh_middle_2013-01-01", "sh_consumer_2013-01-01")
      expect(@job_store.get("sh_producer_2013-01-01")[Patriot::Command::STATE_ATTR]).to eq Patriot::JobStore::JobState::SUCCEEDED
      expect(@job_store.get("sh_middle_2013-01-01")[Patriot::Command::STATE_ATTR]).to eq Patriot::JobStore::JobState::SUCCEEDED
      expect(@job_store.get("sh_consumer_2013-01-01")[Patriot::Command::STATE_ATTR]).to eq Patriot::JobStore::JobState::SUCCEEDED
      args = [
          'register',
          "--config=#{@config}",
          "--retry_dep",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/producer.pbc"
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      job_ids = @job_store.instance_variable_get(:@jobs).keys.map(&:to_s)
      expect(job_ids).to contain_exactly("sh_producer_2013-01-01", "sh_middle_2013-01-01", "sh_consumer_2013-01-01")
      expect(@job_store.get("sh_producer_2013-01-01")[Patriot::Command::STATE_ATTR]).to eq Patriot::JobStore::JobState::WAIT
      expect(@job_store.get("sh_middle_2013-01-01")[Patriot::Command::STATE_ATTR]).to eq Patriot::JobStore::JobState::WAIT
      expect(@job_store.get("sh_consumer_2013-01-01")[Patriot::Command::STATE_ATTR]).to eq Patriot::JobStore::JobState::WAIT
    end

    it "can register with state and keeping state" do
      args = [
          'register',
          "--config=#{@config}",
          "--state=3",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh.pbc",
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(@job_store.get("sh_echo_2013-01-01")['state']).to eq Patriot::JobStore::JobState::SUSPEND
      args = [
          'register',
          "--config=#{@config}",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh.pbc",
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(@job_store.get("sh_echo_2013-01-01")['state']).to eq Patriot::JobStore::JobState::WAIT
    end

    it "can register with state specified in PBC" do
      args = [
          'register',
          "--config=#{@config}",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh_skip.pbc",
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(@job_store.get("sh_echo_skip_2013-01-01")['state']).to eq Patriot::JobStore::JobState::SUCCEEDED
      args = [
          'register',
          "--config=#{@config}",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh_suspend.pbc",
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(@job_store.get("sh_echo_suspend_2013-01-01")['state']).to eq Patriot::JobStore::JobState::SUSPEND
    end

    it "can register with priority" do
      args = [
          'register',
          "--config=#{@config}",
          "--priority=50",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh.pbc",
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(@job_store.get("sh_echo_2013-01-01")['priority']).to eq 50

      # FROM PBC
      args = [
          'register',
          "--config=#{@config}",
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh_priority.pbc",
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(@job_store.get("sh_echo_priority_2013-01-01")['priority']).to eq 99
    end
  end

end
