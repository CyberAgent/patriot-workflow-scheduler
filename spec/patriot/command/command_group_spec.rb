require 'init_test'

describe Patriot::Command::CommandGroup do
  include Patriot::Command::Parser
  before :each do
    @target_datetime = Time.new(2013,1,1)
    @config = config_for_test
    @grouped_command = Patriot::Command::CommandGroup.new(@config)
  end

  describe ".configure" do
    context "when commands is empty" do
      it "should be nil" do
        expect(@grouped_command.subcommands).to eq []
      end
    end
  end

  describe "dsl" do
    it "should not overwirte command param" do
      cmd = new_command(Patriot::Command::CommandGroup) do 
        param 'name' => 'NO'
        sh {
          name 'YES'
          commands 'cmd'
        }
      end
      cmd = cmd.build[0]
      expect(cmd).to be_a Patriot::Command::ShCommand
      expect(cmd.instance_variable_get(:@name)).to eq 'YES'
    end

    it "should set common attrs to children" do
      cmd = new_command(Patriot::Command::CommandGroup) do 
        exec_node 'node'
        priority   9999
        skip_on_fail
        start_after '10:00:00'
        sh {
          name 'YES'
          commands 'cmd'
        }
      end
      cmd = cmd.build[0]
      expect(cmd).to be_a Patriot::Command::ShCommand
      expect(cmd[Patriot::Command::EXEC_NODE_ATTR]).to eq 'node'
      expect(cmd[Patriot::Command::PRIORITY_ATTR]).to eq 9999
      expect(cmd[Patriot::Command::START_DATETIME_ATTR]).to eq Time.new(2013,1,2,10,00,00)
      expect(cmd.post_processors[0]).to be_a Patriot::Command::PostProcessor::SkipOnFail
    end
  end
end
