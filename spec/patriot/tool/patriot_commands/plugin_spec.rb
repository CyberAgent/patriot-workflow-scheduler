require 'init_test'

describe Patriot::Tool::PatriotCommands::Plugin do
  describe "help" do
    it "should show help" do
      args = ['help', 'plugin']
      Patriot::Tool::PatriotCommand.start(args)
    end
  end

  describe "plugin" do

    before :all do
      @config = File.join(ROOT_PATH, "spec", "config", "test.ini")
    end

    before :each do
      @controller = Patriot::Controller::PackageController.new(config_for_test)
      allow(Patriot::Controller::PackageController).to receive(:new).and_return(@controller)
    end

    it "install" do
      args = ['plugin', "--config=#{@config}", 'install', 'plugin_to_be_installed']
      expect(@controller).to receive(:install_plugin).with('plugin_to_be_installed', {:config => @config})
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

  end
end
