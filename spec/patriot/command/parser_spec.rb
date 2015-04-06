require 'init_test'

$dt = '2012-02-08'

describe Patriot::Command::Parser do 
  include Patriot::Command::Parser

  it "sholud not parse each file separately" do
    parser = Patriot::Tool::BatchParser.new(config_for_test)
    commands = parser.parse([1,2].map{|i| File.join($ROOT_PATH, "spec","pbc","exec_node#{i}.pbc") })
    expect(commands[0].instance_variable_get(:@exec_node)).not_to eq commands[1].instance_variable_get(:@exec_node)
  end

end
