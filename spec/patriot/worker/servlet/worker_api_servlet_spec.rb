require 'json'
require 'init_test'
require 'rest_client'
require 'patriot/worker/servlet/worker_api_servlet'

describe Patriot::Worker::Servlet::JobAPIServlet do

  context "default config" do
    before :all do
      @config = config_for_test('worker')
      port = @config.get(Patriot::Worker::InfoServer::PORT_KEY,
                         Patriot::Worker::InfoServer::DEFAULT_PORT)
      @url = "http://127.0.0.1:#{port}"
      @worker = Patriot::Worker::MultiNodeWorker.new(@config)
      @info_server = @worker.instance_variable_get(:@info_server)
      @info_server.start_server
      @client = RestClient::Resource.new("#{@url}/api/v1/workers")
      @client_auth = RestClient::Resource.new("#{@url}/api/v1/workers", :user => "admin", :password => "password")
      sleep 1
    end

    before :each do
      @worker.instance_variable_set(:@status, Patriot::Worker::Status::ACTIVE)
    end

    after :all do
      @info_server.shutdown_server
    end

    it "should get a response with application/json" do
      expect(@client["/"].get().headers[:content_type]
      ).to eq("application/json;charset=utf8")
    end

    it "should get list of workers" do
      expect(JSON.parse(@client["/"].get()
      )).to contain_exactly(
       {"host" => "test-bat01", "port" => "36104"},
       {"host" => "test-bat02", "port" => "36104"}
      )
    end

    it "should get information on the worker" do
      expect(JSON.parse(@client["/this"].get())).to match(
        "state"      => Patriot::Worker::Status::ACTIVE,
        "host"       => anything,
        "version"    => Patriot::VERSION,
        "class"      => @worker.class.to_s,
        "started_at" => @worker.started_at,
        "config"     => {} # TODO
      )
    end
  end
end
