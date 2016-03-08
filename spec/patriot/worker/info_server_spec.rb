require 'init_test'
require 'rest_client'

describe  Patriot::Worker::InfoServer do

  context "default config" do
    before :all do
      @config = config_for_test('worker')
      port = @config.get(Patriot::Worker::InfoServer::PORT_KEY,
                         Patriot::Worker::InfoServer::DEFAULT_PORT)
      @url = "http://127.0.0.1:#{port}"
      username  = @config.get(Patriot::Util::Config::USERNAME_KEY, "")
      password  = @config.get(Patriot::Util::Config::PASSWORD_KEY, "")
      @auth = 'Basic ' + Base64.encode64("#{username}:#{password}").chomp
      @worker = Patriot::Worker::MultiNodeWorker.new(@config)
      @job1 = TestEnvironment.build_job()
      @job2 = TestEnvironment.build_job()
      @job_store = @worker.instance_variable_get(:@job_store)
      @update_id = Time.now.to_i
      @job_store.register(@update_id, [@job1,@job2])
      @info_server = @worker.instance_variable_get(:@info_server)
      @info_server.start_server
      sleep 1
    end

    before :each do
      @worker.instance_variable_set(:@status, Patriot::Worker::Status::ACTIVE)
    end

    after :all do
      @info_server.shutdown_server
    end

    describe "WorkerServlet" do
      it "should controll status (to be modified)" do
        expect(@worker.instance_variable_get(:@status)).to eq Patriot::Worker::Status::ACTIVE
        expect(RestClient.get("#{@url}/worker")).to match Patriot::Worker::Status::ACTIVE
        resource = RestClient::Resource.new("#{@url}/worker/status")
        resource.put({:status => Patriot::Worker::Status::SLEEP}, :Authorization => @auth )
        expect(@worker.instance_variable_get(:@status)).to eq Patriot::Worker::Status::SLEEP
        expect(RestClient.get("#{@url}/worker")).to match Patriot::Worker::Status::SLEEP
      end

      it "should controll worker status" do
        expect(@worker.instance_variable_get(:@status)).to eq Patriot::Worker::Status::ACTIVE
        expect(RestClient.get("#{@url}/worker/status")).to match Patriot::Worker::Status::ACTIVE
        resource = RestClient::Resource.new("#{@url}/worker/status")
        resource.put({:status => Patriot::Worker::Status::SLEEP}, :Authorization => @auth )
        expect(@worker.instance_variable_get(:@status)).to eq Patriot::Worker::Status::SLEEP
        expect(RestClient.get("#{@url}/worker/status")).to match Patriot::Worker::Status::SLEEP
      end
    end

    describe "JobServlet" do
      it "should return job status" do
        job_status = RestClient.get("#{@url}/jobs/#{@job1.job_id}", :accept => :json)
        json = JSON.parse(job_status)
        expect(json["job_id"]).to eq @job1.job_id
        expect(json["state"]).to eq Patriot::JobStore::JobState::WAIT
      end
    end

  end

end
