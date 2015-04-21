require 'init_test'
require 'patriot/util/logger'
require 'patriot/util/logger/factory'
require 'patriot/util/logger/log4r_factory'

describe Patriot::Util::Logger::Log4rFactory do
  include Patriot::Util::Config

  before :all do
    @name  = 'test'
    file = File.join(ROOT_PATH, 'spec', 'config', 'logger.log4r.ini')
    @config = load_config(:path => file)
  end

  describe "should create a Log4r object" do
    include Patriot::Util::Logger
    it "create_logger like function" do
      logger = create_logger(@config)
      _logger = logger.instance_variable_get(:@logger)
      expect(_logger).to be_a Log4r::Logger
    end
  end

  describe "build" do
    it "should create outputters" do
      logger = Patriot::Util::Logger::Log4rFactory.instance.get_logger(@name, @config)
      _logger = logger.instance_variable_get(:@logger)
      expect(_logger).to be_a Log4r::Logger
      expect(_logger.level).to eq 4
      expect(_logger.outputters.size).to eq 3
    end
  end

  describe "logging" do
    it "should log exceptions" do
      logger = Patriot::Util::Logger::Log4rFactory.instance.get_logger(@name, @config)
      _logger = logger.instance_variable_get(:@logger)
      exp = Exception.new("msg")
      exp.set_backtrace(["t1","t2"])
      expect(_logger).to receive(:info).with("msg")
      expect(_logger).to receive(:info).with("t1")
      expect(_logger).to receive(:info).with("t2")
      logger.info(exp)
    end
  end
end
