require 'json'
require 'init_test'
require 'rest_client'
require 'patriot/worker/servlet/config_api_servlet'
require 'patriot/version'

describe Patriot::Worker::Servlet::ConfigAPIServlet do

  context "default config" do
    before :all do
      @config = config_for_test('worker')
      port = @config.get(Patriot::Worker::InfoServer::PORT_KEY,
                         Patriot::Worker::InfoServer::DEFAULT_PORT)
      @url = "http://127.0.0.1:#{port}"
      @worker = Patriot::Worker::MultiNodeWorker.new(@config)
      @info_server = @worker.instance_variable_get(:@info_server)
      @info_server.start_server
      @client = RestClient::Resource.new("#{@url}/api/v1/config")
      @client_auth = RestClient::Resource.new("#{@url}/api/v1/config", :user => "admin", :password => "password")
      sleep 1
    end

    before :each do
      @worker.instance_variable_set(:@status, Patriot::Worker::Status::ACTIVE)
    end

    after :all do
      @info_server.shutdown_server
    end

    it "should get information on the worker" do
      expect(JSON.parse(@client["/"].get())).to match(
        "version"    => Patriot::VERSION,
        "class"      => @worker.class.to_s,
        "started_at" => @worker.started_at,
        "config"     => {} # TODO
      )
    end
  end
end
