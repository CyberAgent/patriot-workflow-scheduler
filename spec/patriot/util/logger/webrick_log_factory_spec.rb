require 'init_test'
require 'webrick'
require 'patriot/util/logger'
require 'patriot/util/logger/factory'
require 'patriot/util/logger/webrick_log_factory'

describe Patriot::Util::Logger::WebrickLogFactory do
  include Patriot::Util::Config

  before :all do
    @name   = 'test'
    file = File.join($ROOT_PATH, 'spec', 'config', 'logger.webrick.ini')
    @config = load_config(:path => file)
  end

  describe "should create a Log4r object" do
    include Patriot::Util::Logger
    it "create_logger like function" do
      logger = create_logger(@config)
      _logger = logger.instance_variable_get(:@logger)
      expect(_logger).to be_a WEBrick::BasicLog
    end
  end
end
