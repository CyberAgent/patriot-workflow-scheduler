require 'init_test'

describe "Patriot::Tool::BatchParser" do
  before :each do
    @obj = Patriot::Tool::BatchParser.new(config_for_test)
    @files = [
        File.join($ROOT_PATH, 'spec', 'pbc', 'exec_node1.pbc'),
        File.join($ROOT_PATH, 'spec', 'pbc', 'exec_node2.pbc')
      ]
  end

  describe ".parse" do
    it "should be node1" do
      pbc_file = File.join($ROOT_PATH, 'spec', 'pbc', 'exec_node1.pbc')
      commands = @obj.parse(pbc_file)
      expect(commands[0][Patriot::Command::EXEC_NODE_ATTR]).to eq "node1"
    end

    it "should be each configured value" do
      commands = @obj.parse(@files)
      expect(commands[0][Patriot::Command::EXEC_NODE_ATTR]).to eq "node1"
      expect(commands[1][Patriot::Command::EXEC_NODE_ATTR]).to eq nil
    end

    it "should filter by job_id" do
      commands = @obj.parse(@files, {:filter => 'sh_c1_'})
      expect(commands.size).to eq 1
    end

    it "should raise an error" do
      files = "/tmp/no_such_a_file.pbc"
      expect {@obj.parse(files) }.to raise_error
    end

    it "should process macro" do
      files = [
          $ROOT_PATH + '/spec/pbc/macro.pbc',
        ]
      commands = @obj.parse(files)
      expect(commands.size).to eq 2
      shs = commands.map{|c| c.instance_variable_get(:@commands)[0]}
      expect(shs).to include "MACROtest1"
      expect(shs).to include "MACROtest2"
    end

    it "should raise an error" do
      @obj.parse(@files)
      expect { @obj.register() }. to raise_error
    end
  end

  describe ".dsl_parser" do
    it "should return an appropriate class object" do
      expect(@obj.dsl_parser).to be_a Patriot::Command::CommandGroup
    end
    describe "basic commands" do 
      [:job_group, :composite_job, :sh, :command_group, :composite_command].each do |cmd|
        it "should respond to #{cmd}" do
          expect(@obj.dsl_parser).to respond_to(cmd)
        end
      end
    end
  end

end
