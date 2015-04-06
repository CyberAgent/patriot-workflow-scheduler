require 'init_test'
require 'patriot/util/config'

describe Patriot::Util::Config do
  before :each do
    @obj = Object.new
    @obj.extend(Patriot::Util::Config)
  end

  describe "#load_config" do
    it "should respond to" do
      expect(@obj).to respond_to(:load_config)
    end

    it "should raise an error" do
      expect {@obj.load_config({:path => "NONEXISTCONFIG"})}.to raise_error
    end

    it "should ignore plugin" do
      file = File.join($ROOT_PATH, 'spec', 'config', 'test.plugin.ini')
      expect(@obj).not_to receive(:load_plugin)
      @obj.load_config({:ignore_plugin => true, :path => file})
    end
  end 


end
