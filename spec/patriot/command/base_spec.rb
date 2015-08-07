require 'date'
require 'init_test'
$: << File.dirname(File.expand_path(__FILE__))

YEAR  = 1970
MONTH = 01
DAY   = 01

describe Patriot::Command::Base do 
  include Patriot::Command::Parser
  before :all do
    @config = config_for_test
    @target_datetime = Time.new(YEAR, MONTH, DAY)
  end

  it "sholud extract start after" do
    cmd = new_command(Patriot::Command::ShCommand) do
      produce ["product1_#{@hour}"]  
      require ["product2_#{@hour}"]  
      param 'hour' => '00'
      exec_date '1970-01-01'
      start_after '#{@hour}:00:00'
      name 'test_import_#{@hour}'
      commands 'echo \'#{@hour}\''
    end
    cmds = cmd.build
    expect(cmds.size).to eq 1
    expect(cmds[0].start_date_time).to eq Time.new(YEAR,MONTH,DAY,0,0,0)
  end

  it "sholud not have reserved word" do
    cmd = new_command(Patriot::Command::ShCommand) do
      produce ["product1_#{@hour}"]  
      require ["product2_#{@hour}"]  
      param "#{Patriot::Command::COMMAND_CLASS_KEY}" => 'test'
      name 'test_import_#{@hour}'
      commands 'echo \'#{@hour}\''
    end
    expect{cmd.build}.to raise_error
  end

  it "sholud handle double quote" do
    cmd = new_command(Patriot::Command::ShCommand) do
      name 'test_"import'
      commands "echo \"#{YEAR}\""
    end
    cmd       = cmd.build[0]
    job       = cmd.to_job
    cmd       = job.to_command(@config)
    expect(cmd.instance_variable_get(:@commands)[0]).to eq "echo \"#{YEAR}\""
  end

  it "sholud be suspended" do
    cmd = new_command(Patriot::Command::ShCommand) do
      suspend
      name 'test_"import'
      commands "echo \"#{YEAR}\""
    end
    cmd     = cmd.build[0]
    expect(cmd.instance_variable_get(:@state)).to eq Patriot::JobStore::JobState::SUSPEND
  end

  it "sholud be skipped" do
    cmd = new_command(Patriot::Command::ShCommand) do
      skip
      name 'test_"import'
      commands "echo \"#{YEAR}\""
    end
    cmd     = cmd.build[0]
    expect(cmd.instance_variable_get(:@state)).to eq Patriot::JobStore::JobState::SUCCEEDED
  end

  describe "class methods" do
    it "should respond to add_dsl_function" do
      expect(Patriot::Command::Base).to respond_to :add_dsl_function
    end

    it "should respond to" do
      expect(Patriot::Command::Base).to respond_to :command_attr
    end
  end

  describe "instance methods" do

    before :each do
      @command = Patriot::Command::Base.new(config_for_test)
    end

    describe "description" do
      it "should not implement description " do
        expect{@command.description}.to raise_error
      end
    end

    describe "require" do
      it "expect to railse error without correct arguments" do
        expect { @command.require()           }.to raise_error 
        expect { @command.require(1)          }.to raise_error
      end

      it "expect to receive an array" do
        @command.require [1, 2, 3]
        expect(@command['requisites']).to contain_exactly(1, 2, 3)
      end
    end

    describe "produce" do
      it "expect to railse error without arguments" do
        expect { @command.produce()}.to raise_error 
        expect { @command.produce(1)}.to raise_error 
      end

      it "expect to receive an array" do
        @command.produce [1, 2, 3]
        expect(@command['products']).to contain_exactly(1, 2, 3)
      end
    end

    describe "param" do
      it "should raise an error with nil" do
        expect {@command.param}.to raise_error
      end

      it "should be attached a new parameter" do
        expect{@command.param({:indicator => "login_uu"})}.to change{@command.instance_variable_get(:@param)}.
                                                                     from({}).to({:indicator => "login_uu"})
      end
    end

    describe "build" do
      it "should call configure of clone" do 
        expect(@command).to receive(:configure).and_return(@command)
        @command.build
      end
    end

    describe "cnofigure" do
      it "should have default implementation" do
        expect(@command.configure).to eq @command
      end
    end

    describe "configure_attr" do
      # TODO
      it { expect(@command).to respond_to(:configure_attr) }
    end

    describe "eval_attr" do
      # TODO
      it { expect(@command).to respond_to(:eval_attr) }
    end
  end
end
