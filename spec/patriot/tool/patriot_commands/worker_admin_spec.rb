require 'init_test'
require 'patriot/tool/patriot_commands/worker_admin'

describe Patriot::Tool::PatriotCommands::WorkerAdmin do
  describe "help" do
    it "should show help" do
      args = ['help', 'worker_admin']
      Patriot::Tool::PatriotCommand.start(args)
    end
  end

  describe "worker_admin" do
    it "should output status of worker" do
      $stdout = StringIO.new
      args = ['worker_admin', 'status', 
              '-h', 'test-bat01',
              '-c', path_to_test_config] 
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      json = JSON.parse($stdout.string)
      expect(json.size).to eq 1
      expect(json['test-bat01']).to eq "HALT"
      $stdout = STDOUT
    end

    it "should output status of workers" do
      $stdout = StringIO.new
      args = ['worker_admin', 'status', 
              '-a',
              '-c', path_to_test_config] 
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      json = JSON.parse($stdout.string)
      expect(json.size).to eq 2
      expect(json['test-bat01']).to eq "HALT"
      expect(json['test-bat02']).to eq "HALT"
      $stdout = STDOUT
    end
  end

  describe "upgrade" do
    before :each do
      @controller = Patriot::Controller::WorkerAdminController.new(config_for_test)
      allow(Patriot::Controller::WorkerAdminController).to receive(:new).and_return(@controller)
    end

    it "should upgrade workers" do 
      expect(@controller).to receive(:upgrade_worker)
      args = ['worker_admin', 'upgrade', 
              '-h', '127.0.0.1',
              '-c', path_to_test_config] 
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

  end
end
