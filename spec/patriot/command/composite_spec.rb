require 'init_test'
$: << File.dirname(File.expand_path(__FILE__))

$dt = '2011-12-12'

describe Patriot::Command::ShCommand do 
  include Patriot::Command::Parser
  tmp_file="/tmp/pac3_composite_spec_msg"
  before :all do 
    @config = config_for_test
    @valid_cmd1 = new_command(Patriot::Command::CompositeCommand) { 
      job_group{
        sh {
          require ['a']
          name 'test1'
          commands 'echo \'test1\' >> /tmp/pac3_composite_spec_msg' # TMP_FILE
        }
        sh {
          produce ['b']
          name 'test2'
          commands 'echo \'test2\' >> /tmp/pac3_composite_spec_msg' # TMP_FILE
        }
      }
    }
    @valid_cmd1 = @valid_cmd1.build[0]
  end

  before :each do 
    FileUtils.rm_r(tmp_file) if File.exist?(tmp_file) 
  end

  it "sholud execute a multiple command sequentially" do
    @valid_cmd1.execute
    File.open(tmp_file) do |f|
      output = f.readlines
      expect(output).to contain_exactly("test1\n", "test2\n")
    end
  end

  it "sholud handle dependency of contained jobs" do
    expect(@valid_cmd1['requisites']).to contain_exactly('a')
    expect(@valid_cmd1['products']).to contain_exactly('b')
  end
end
