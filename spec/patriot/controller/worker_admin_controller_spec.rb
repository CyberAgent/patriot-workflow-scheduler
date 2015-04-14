require 'init_test'

describe Patriot::Controller::WorkerAdminController  do
  before :each do
    @config     = config_for_test
    @worker     = Patriot::Worker::MultiNodeWorker.new(@config)
    @controller = Patriot::Controller::WorkerAdminController.new(@config)
  end

  describe "status" do

    before :each do
      allow(Process).to receive(:daemon)
      @worker.instance_variable_get(:@info_server).start_server
      sleep 1
    end

    after :each do
      @worker.instance_variable_get(:@info_server).shutdown_server
    end

    it "should get status" do
      @worker.status = Patriot::Worker::Status::ACTIVE
      expect(@controller.status({:host => "127.0.0.1"})["127.0.0.1"]).to match Patriot::Worker::Status::ACTIVE
    end

    it "should sleep and wake up workers" do
      @worker.status = Patriot::Worker::Status::ACTIVE
      @controller.sleep_worker({:host => "127.0.0.1"})
      expect(@controller.status({:host => "127.0.0.1"})["127.0.0.1"]).to match Patriot::Worker::Status::SLEEP
      @controller.wake_worker({:host => "127.0.0.1"})
      expect(@controller.status({:host => "127.0.0.1"})["127.0.0.1"]).to match Patriot::Worker::Status::ACTIVE
    end
  end

  describe "start" do
    it "should start all workers" do
      expect(@controller).to receive(:controll_worker_at).with("test-bat01","start")
      expect(@controller).to receive(:controll_worker_at).with("test-bat02","start")
      @controller.start_worker({:all => true})
    end
  end

  describe "stop" do
    it "should stop all workers" do
      expect(@controller).to receive(:controll_worker_at).with("test-bat01","stop")
      expect(@controller).to receive(:controll_worker_at).with("test-bat02","stop")
      @controller.stop_worker({:all => true})
    end
  end

  describe "restart" do
    it "should restart workers" do
      res_200 = double("res_200")
      allow(res_200).to receive(:code).and_return(200)
      allow(@controller).to receive(:get_worker_status).and_return(res_200,nil,nil)
      expect(@controller).to receive(:controll_worker_at).with("test-bat01","stop")
      expect(@controller).to receive(:controll_worker_at).with("test-bat02","stop")
      expect(@controller).to receive(:controll_worker_at).with("test-bat01","start")
      expect(@controller).to receive(:controll_worker_at).with("test-bat02","start")
      Timeout::timeout(5){
        @controller.restart_worker({:all => true, :interval => 0})
      }
    end
  end

  describe "request_to_target_hosts" do
    it "default options" do
      expect {
        @controller.request_to_target_hosts({}){|host,port|}
      }.to raise_error
    end

    it "with host option" do
      options = {:host => 'localhost'}
      result = []
      expect {
        @controller.request_to_target_hosts(options){ |host,port| 
          result << [host,port]
        }
      }.not_to raise_error
      expect(result).to contain_exactly(["localhost", "36104"])
    end

    it "with hosts option" do
      options = {:hosts => ['localhost', '127.0.0.1']}
      options = {:hosts => 'localhost,127.0.0.1'}
      result = []
      expect {
        @controller.request_to_target_hosts(options){|host,port| 
          result << [host,port]
        }
      }.not_to raise_error
      expect(result).to contain_exactly(["localhost", "36104"], ["127.0.0.1", "36104"])
    end

    it "with all option" do
      options = {:all => true}
      result = []
      expect {
        @controller.request_to_target_hosts(options){|host,port| 
          result << [host,port]
        }
      }.not_to raise_error
      expect(result).to contain_exactly(["test-bat01", "36104"], ["test-bat02", "36104"])

      result = []
      controller = @controller.clone
      controller.instance_variable_set(:@default_hosts, 'localhost')
      controller.request_to_target_hosts(options){|host,port| 
        result << [host,port]
      }
      expect(result).to contain_exactly(["localhost", "36104"])
    end
  end
end
