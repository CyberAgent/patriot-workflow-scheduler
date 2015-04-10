require 'init_test'
require 'patriot/tool/patriot_commands/execute'

describe Patriot::Tool::PatriotCommands::Execute do
  describe "execute" do
    it "should show help" do
      args = ['help']
      Patriot::Tool::PatriotCommand.start(args)
    end
  end

  describe "execute" do

    it "single file with default setting" do
      args = [
          'execute', 
          '-c', path_to_test_config,
          '2013-01-01', 
          "#{ROOT_PATH}/spec/pbc/sh.pbc"
        ]
      expect_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command).with("echo 2013-01-01")
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      
    end

    it "single file with debug" do
      args = [
          'execute', 
          '--debug',
          '-c', path_to_test_config,
          '2013-01-01', 
          "#{ROOT_PATH}/spec/pbc/sh.pbc"
        ]
      expect_any_instance_of(Patriot::Command::ShCommand).not_to receive(:execute_command)
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "single file in test mode" do
      args = [
          'execute', 
          '--test',
          '-c', path_to_test_config,
          '2013-01-01', 
          "#{ROOT_PATH}/spec/pbc/sh.pbc"
        ]
      expect_any_instance_of(Patriot::Command::ShCommand).to receive(:test_mode=).with(true)
      expect_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command)
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "directory" do
      args = [
          'execute',
          '-c', path_to_test_config,
          '2013-01-01',
          "#{ROOT_PATH}/spec/pbc/sh"
        ]
      expect_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command).with("echo 2013-01-01")
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "multiple paths" do
      args = [
          'execute',
          '-c', path_to_test_config,
          '2013-01-01,2013-01-02',
          "#{ROOT_PATH}/spec/pbc/sh.pbc",
          "#{ROOT_PATH}/spec/pbc/sh/daily",
          "#{ROOT_PATH}/spec/pbc/sh/weekly",
          "#{ROOT_PATH}/spec/pbc/sh/monthly",
        ]
      # use cnt value dues allow_any_instance_of().to recieve.extactry(2).times does not work
      cnt = {"2013-01-01"=>0, "2013-01-02"=>0}
      allow_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command).
        with("echo 2013-01-01"){|a| cnt["2013-01-01"]+=1}
      allow_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command).
        with("echo 2013-01-02"){|a| cnt["2013-01-02"]+=1}
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(cnt["2013-01-01"]).to eq 2
      expect(cnt["2013-01-02"]).to eq 2
    end

    it "should run in strict mode" do
      args = [
          'execute', 
          '--strict',
          '-c', path_to_test_config,
          '2013-01-01', 
          "#{ROOT_PATH}/spec/pbc/consumer.pbc",
          "#{ROOT_PATH}/spec/pbc/producer.pbc",
        ]
      seq = ""
      allow_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command).with("echo first")  { |a| seq << "f" }
      allow_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command).with("echo second") { |a| seq << "s" }
      allow_any_instance_of(Patriot::Command::ShCommand).to receive(:execute_command).with("echo third")  { |a| seq << "t" }
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect(seq).to eq "fst"
    end

    it "should not accept test and debug at once" do
      args = [
          'execute', 
          '--debug',
          '--test',
          '-c', path_to_test_config,
          '2013-01-01', 
          "#{ROOT_PATH}/spec/pbc/sh.pbc"
        ]
      expect{Patriot::Tool::PatriotCommand.start(args)}.to raise_error
    end
  end
end
