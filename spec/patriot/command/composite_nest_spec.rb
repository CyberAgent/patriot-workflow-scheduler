require 'init_test'
$: << File.dirname(File.expand_path(__FILE__))

tmp_file = "/tmp/pac3_composite_nest_spec_msg"

describe Patriot::Command::CompositeCommand do 
  include Patriot::Command::Parser
  before :all do 
    @target_datetime = DateTime.new(2011,12,12)
    @config = config_for_test
    @valid_cmd1 = new_command(Patriot::Command::CompositeCommand) do 
      param 'tmp_file' => "/tmp/pac3_composite_nest_spec_msg"
      command_group{
        composite_command {
          sh {
            require ['a']
            name 'test1'
            commands 'echo \'test1\' >> #{@tmp_file}' # TMP_FILE
          }
        }
        sh {
          produce ['b']
          name 'test2'
          commands 'echo \'test2\' >> #{@tmp_file}' # TMP_FILE
        }
      }
    end
    @valid_cmd1 = @valid_cmd1.build[0]
  end

  before :each do 
    FileUtils.rm_r(tmp_file) if File.exist?(tmp_file) 
  end

  it "sholud execute a multiple command sequentially" do
    @valid_cmd1.execute
    File.open(tmp_file) do |f|
      output = f.readlines
      expect(output).to eq ["test1\n", "test2\n"]
    end
  end

  it "sholud handle dependency of contained commands" do
    expect(@valid_cmd1['requisites']).to contain_exactly('a')
    expect(@valid_cmd1['products']).to contain_exactly('b')
  end
end
