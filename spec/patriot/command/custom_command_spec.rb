require 'init_test'
$: << File.dirname(File.expand_path(__FILE__))

class TestCustomCommand < Patriot::Command::Base
  declare_command_name :test_command
  command_attr :name, :hash_attr
  def job_id
    return "#{command_name}_#{@name}"
  end

  def execute
    puts @hash_attr
  end
end

describe TestCustomCommand do
  include Patriot::Command::Parser
  before :all do
    @target_datetime = Time.new(2011,12,12)
    @config = config_for_test
    @valid_cmd = new_command(TestCustomCommand) do
      name "test"
      hash_attr "k" => "v"
    end
    @valid_cmd = @valid_cmd.build[0]
  end

  it "should serialize hash attributes" do
    job = @valid_cmd.to_job
    cmd = job.to_command(@config)
    expect(cmd.instance_variable_get(:@hash_attr)).to match({"k" => "v"})
  end
end

