require 'init_test'
require 'patriot/tool/patriot_command'

describe Patriot::Tool::PatriotCommand do
  describe "help" do
    it "should show help message" do
      args = ['help']
      Patriot::Tool::PatriotCommand.start(args)
    end
  end
end
