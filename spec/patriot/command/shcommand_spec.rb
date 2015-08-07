require 'init_test'
$: << File.dirname(File.expand_path(__FILE__))

describe Patriot::Command::ShCommand do 
  include Patriot::Command::Parser
  tmp_file="/tmp/pac3_shcommand_spec_msg"
  before :all do 
    @target_datetime = Time.new(2011,12,12)
    @config = config_for_test
    @valid_cmd1 = new_command(Patriot::Command::ShCommand) do 
      produce ["product1"]  
      exec_node 'localhost'
      param 'msg' => 'hello'
      start_after '12:00:00'
      name 'test_import'
      commands 'echo \'#{@msg}\' > /tmp/pac3_shcommand_spec_msg' # TMP_FILE
    end
    @valid_cmd1 = @valid_cmd1.build[0]
    @invalid_cmd1 = new_command(Patriot::Command::ShCommand) do 
      produce ["product2"]  
      param 'msg' => 'hello'
      start_after '12:00:00'
      name 'test_import'
      commands 'cat #{$home}/tmp/no_file' # the file is not exist
    end
    @invalid_cmd1 = @invalid_cmd1.build[0]
  end

  before :each do 
    FileUtils.rm_r(tmp_file) if File.exist?(tmp_file) 
  end

  it "sholud execute a command" do
    parser = Patriot::Tool::BatchParser.new(config_for_test)
    @valid_cmd1.execute
    File.open(tmp_file) do |f|
      dat = f.read
      expect(dat.chomp).to eq'hello'
    end   
  end

  it "sholud raise an error" do
    parser = Patriot::Tool::BatchParser.new(config_for_test)
    expect{
      @invalid_cmd1.execute
    }.to raise_error(Patriot::Util::System::ExternalCommandException)
  end

  it "sholud have a name" do
    noname = new_command(Patriot::Command::ShCommand) do 
      commands 'echo /tmp/no_name' 
    end
    expect{noname.build}.to raise_error
  end

  it "sholud has default connector name" do
    cmd = new_command(Patriot::Command::ShCommand) do 
      name 'default_connector'
      commands 'echo /tmp/no_name' 
    end
    cmd = cmd.build[0]
    expect(cmd.instance_variable_get(:@connector)).to eq '&&'
  end
end
