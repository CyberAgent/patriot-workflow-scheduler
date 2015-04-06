# -*- coding: utf-8 -*-
require 'init_test'
require 'patriot/job_store/job'

describe Patriot::JobStore::Job do

  before :all do
    @config = config_for_test
  end

  describe "initialize" do
    it "should create command" do
      jobstore = Patriot::JobStore::InMemoryStore.new('root',@config)
      cmd = Patriot::Command::ShCommand.new(@config)
      cmd.name 'test'
      cmd.commands 'test cmd'
      job = cmd.to_job
      expect(job.job_id).to eq cmd.job_id
      expect(job['state']).to be Patriot::JobStore::JobState::INIT
      expect(job['commands']).to contain_exactly('test cmd')

      _cmd = job.to_command(@config)
      expect(_cmd).to be_a Patriot::Command::ShCommand
      expect(_cmd.instance_variable_get(:@commands)).to contain_exactly('test cmd')
    end
  end

  describe "conversion between job and command" do
    it "should preserve newline " do
      cmd = Patriot::Command::ShCommand.new(@config)
      shcmd = <<EOS
echo 'test
test'
EOS
      cmd.commands shcmd
      cmd.name = "test"
      job = Patriot::JobStore::Job.new(cmd.job_id)
      job.read_command(cmd)
      expect(job['commands'][0]).to eq shcmd

      _cmd = job.to_command(@config)
      expect(_cmd).to be_a Patriot::Command::ShCommand
      expect(_cmd.instance_variable_get(:@commands).size).to eq 1
      expect(_cmd.instance_variable_get(:@commands)[0]).to eq shcmd

    end

    it "should preserve japanese words" do
      cmd = Patriot::Command::ShCommand.new(config_for_test)
      cmd.commands "echo 'テスト'"
      cmd.name = "test"
      job = Patriot::JobStore::Job.new(cmd.job_id)
      job.read_command(cmd)
      expect(job['commands'].size).to eq 1
      expect(job['commands'][0]).to eq "echo 'テスト'"

      _cmd = job.to_command(@config)
      expect(_cmd).to be_a Patriot::Command::ShCommand
      expect(_cmd.instance_variable_get(:@commands).size).to eq 1
      expect(_cmd.instance_variable_get(:@commands)[0]).to eq "echo 'テスト'"
    end

    it "should convert composite commands" do
      cmd = Patriot::Command::CompositeCommand.new(config_for_test)
      cmd.name = "test"
      sh1 = Patriot::Command::ShCommand.new(config_for_test)
      sh1.commands 'echo 1'
      sh1.name = "test1"
      sh2 = Patriot::Command::ShCommand.new(config_for_test)
      sh2.commands 'echo 2'
      sh2.name = "test2"
      cmd.instance_variable_set(:@contained_commands, [sh1, sh2])
      job = Patriot::JobStore::Job.new(cmd.job_id)
      job.read_command(cmd)
      expect(job['contained_commands'].size).to eq 2
      expect(job['contained_commands'][0][Patriot::Command::COMMAND_CLASS_KEY]).to eq 'Patriot.Command.ShCommand'
      expect(job['contained_commands'][0]['commands']).to contain_exactly 'echo 1'

      _cmd = job.to_command(@config)
      expect(_cmd).to be_a Patriot::Command::CompositeCommand
      expect(_cmd.instance_variable_get(:@contained_commands).size).to eq 2
      _sh1 = cmd.instance_variable_get(:@contained_commands)[0]
      expect(_sh1).to be_a Patriot::Command::ShCommand
      expect(_sh1.instance_variable_get(:@commands).size).to eq 1
      expect(_sh1.instance_variable_get(:@commands)[0]).to eq 'echo 1'
      _sh2 = cmd.instance_variable_get(:@contained_commands)[1]
      expect(_sh2).to be_a Patriot::Command::ShCommand
      expect(_sh2.instance_variable_get(:@commands).size).to eq 1
      expect(_sh2.instance_variable_get(:@commands)[0]).to eq 'echo 2'
    end
  end

end

