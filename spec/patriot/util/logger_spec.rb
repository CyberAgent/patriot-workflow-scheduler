require 'init_test'
require 'patriot/util/logger'

describe Patriot::Util::Logger do
  before :each do
    @obj = Object.new
    @obj.extend(Patriot::Util::Logger)
  end

  describe "create_logger" do
    it "should respond to create logger" do
      file = File.join(ROOT_PATH, 'spec', 'config', 'logger.base.ini')
      conf = load_config(:path => file)
      expect(@obj).to respond_to(:create_logger).with(1).argument
    end
  end

end
