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
      logger = @obj.create_logger(conf)
      expect(logger).to be_a Patriot::Util::Logger::Facade
    end
  end

end
