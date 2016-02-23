require 'json'
require 'init_test'
require 'rest_client'
require 'patriot/worker/servlet/job_api_servlet'

describe Patriot::Worker::Servlet::JobAPIServlet do

  context "default config" do
    before :all do
      @config = config_for_test('worker')
      port = @config.get(Patriot::Worker::InfoServer::PORT_KEY,
                         Patriot::Worker::InfoServer::DEFAULT_PORT)
      @url = "http://127.0.0.1:#{port}"
      @worker = Patriot::Worker::MultiNodeWorker.new(@config)
      @job1 = TestEnvironment.build_job({:job_id => "wait1", :produce => ["p1"]})
      @job2 = TestEnvironment.build_job({:job_id => "wait2", :require => ["p1"]})
      @job3 = TestEnvironment.build_job({:job_id => "running",
                                         :state => Patriot::JobStore::JobState::RUNNING})
      @job4 = TestEnvironment.build_job({:job_id => "failed",
                                         :state => Patriot::JobStore::JobState::FAILED})
      @update_id = Time.now.to_i
      @job_store = @worker.instance_variable_get(:@job_store)
      @job_store.register(@update_id, [@job1,@job2,@job3,@job4])
      @info_server = @worker.instance_variable_get(:@info_server)
      @info_server.start_server
      @client = RestClient::Resource.new("#{@url}/api/v1/jobs")
      @client_auth = RestClient::Resource.new("#{@url}/api/v1/jobs", :user => "admin", :password => "password")

      sleep 1
    end

    before :each do
      @worker.instance_variable_set(:@status, Patriot::Worker::Status::ACTIVE)
    end

    after :all do
      @info_server.shutdown_server
    end


    it "should get stats" do
      expect(JSON.parse(@client["/stats"].get()
      )).to match_array([
        [Patriot::JobStore::JobState::INIT.to_s,    0],
        [Patriot::JobStore::JobState::WAIT.to_s,    2],
        [Patriot::JobStore::JobState::RUNNING.to_s, 1],
        [Patriot::JobStore::JobState::SUSPEND.to_s, 0],
        [Patriot::JobStore::JobState::FAILED.to_s,  1]
      ])
    end


    it "should get jobs" do
      expect(JSON.parse(@client.get()
      )).to match_array([{"state" => Patriot::JobStore::JobState::FAILED,
                          "job_id" => "sh_job_failed_2015-04-01"}])

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::RUNNING}}
      ))).to match_array([{"state" => Patriot::JobStore::JobState::RUNNING,
                           "job_id" => "sh_job_running_2015-04-01"}])

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT}}
      ))).to match_array([{"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait1_2015-04-01"},
                          {"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait2_2015-04-01"}])

      # expect wait2 (since registered later than wait1)
      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT,
                     :limit => 1}}
      ))).to match_array([{"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait2_2015-04-01"}])

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT,
                     :limit => 1,
                     :offset => 1}}
      ))).to match_array([{"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait1_2015-04-01"}])

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT,
                     :filter_exp => "%wait1%"}}
      ))).to match_array([{"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait1_2015-04-01"}])
    end


    it "should not get any jobs" do
      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::SUSPEND}}
      ))).to match_array([])

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT,
                     :limit => 0}}
      ))).to match_array([])

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT,
                     :offset => 2}}
      ))).to match_array([])

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT,
                     :filter_exp => "%never_match%"}}
      ))).to match_array([])
    end


    it "should get the detail of a specified job" do
      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get()
      )).to include(
        {
          "COMMAND_CLASS" => "Patriot.Command.ShCommand",
          "job_id"        => "sh_job_wait1_2015-04-01",
          "priority"      => 1,
          "state"         => Patriot::JobStore::JobState::WAIT
        }
      )
    end


    it "should add a new job" do
      expect{JSON.parse(@client['/sh_newjob_2015-04-01'].get()
      )}.to raise_error(RestClient::ResourceNotFound)

      expect(JSON.parse(@client_auth.post(
        JSON.generate({
          "COMMAND_CLASS" => "Patriot.Command.ShCommand",
          "name"          => "newjob",
          "name_suffix"   => "2015-04-01",
          "priority"      => 10,
          "exec_node"     => "calc_node",
          "exec_date"     => "2015-04-02",
          "start_after"   => "01:30:00"
        }),
        {:content_type => :json}
      ))).to eq({"job_id" => "sh_newjob_2015-04-01"})

      expect(JSON.parse(@client['/sh_newjob_2015-04-01'].get()
      )).to include(
        {
          "COMMAND_CLASS"  => "Patriot.Command.ShCommand",
          "job_id"         => "sh_newjob_2015-04-01",
          "priority"       => 10,
          "state"          => Patriot::JobStore::JobState::WAIT,
          "exec_node"      => "calc_node",
          "start_datetime" => "2015-04-02 01:30:00 +0900"
        }
      )
    end

    it "should re-initialize an existing job" do
      expect(JSON.parse(@client['/sh_job_running_2015-04-01'].get()
      )).to include(
        {
          "COMMAND_CLASS"  => "Patriot.Command.ShCommand",
          "job_id"         => "sh_job_running_2015-04-01",
          "priority"       => 1,
          "state"          => Patriot::JobStore::JobState::RUNNING
        }
      )

      expect(JSON.parse(@client_auth.post(
        JSON.generate({
          "COMMAND_CLASS" => "Patriot.Command.ShCommand",
          "name"          => "job_running",
          "name_suffix"   => "2015-04-01",
          "priority"      => 10,
          "state"          => Patriot::JobStore::JobState::SUSPEND,
          "exec_node"     => "batch_node",
          "exec_date"     => "2015-04-02",
          "start_after"   => "03:30:00"
        }),
        {:content_type => :json}
      ))).to eq({"job_id" => "sh_job_running_2015-04-01"})

      expect(JSON.parse(@client['/sh_job_running_2015-04-01'].get()
      )).to include(
        {
          "COMMAND_CLASS"  => "Patriot.Command.ShCommand",
          "job_id"         => "sh_job_running_2015-04-01",
          "priority"       => 10,
          "state"          => Patriot::JobStore::JobState::SUSPEND,
          "exec_node"      => "batch_node",
          "start_datetime" => "2015-04-02 03:30:00 +0900"
        }
      )

      expect(JSON.parse(@client_auth.post(
        JSON.generate({
          "COMMAND_CLASS" => "Patriot.Command.ShCommand",
          "name"          => "job_running",
          "name_suffix"   => "2015-04-01",
          "priority"      => 10,
          "exec_node"     => "batch_node",
          "exec_date"     => "2015-04-02",
          "start_after"   => "03:30:00"
        }),
        {:content_type => :json}
      ))).to eq({"job_id" => "sh_job_running_2015-04-01"})

      expect(JSON.parse(@client['/sh_job_running_2015-04-01'].get()
      )).to include(
        {
          "COMMAND_CLASS"  => "Patriot.Command.ShCommand",
          "job_id"         => "sh_job_running_2015-04-01",
          "priority"       => 10,
          "state"          => Patriot::JobStore::JobState::WAIT,
          "exec_node"      => "batch_node",
          "start_datetime" => "2015-04-02 03:30:00 +0900"
        }
      )
    end

    it "should change the status of a specified job" do
      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get()
      )).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})

      expect(JSON.parse(@client_auth['/sh_job_wait1_2015-04-01'].patch(
        JSON.generate({:state => Patriot::JobStore::JobState::SUSPEND}), {:content_type => :json}
      ))).to contain_exactly({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})

      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get()
      )).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})

      expect(JSON.parse(@client_auth['/sh_job_wait1_2015-04-01'].patch(
        JSON.generate({:state => Patriot::JobStore::JobState::WAIT}), {:content_type => :json}
      ))).to contain_exactly({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})

      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get()
      )).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
    end

    it "should change the status of a specified job and its followers" do
      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
      expect(JSON.parse(@client['/sh_job_wait2_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})

      expect(JSON.parse(@client_auth['/sh_job_wait1_2015-04-01'].patch(
        JSON.generate({:state => Patriot::JobStore::JobState::SUSPEND, :option => { :with_subsequent => true }}),
        {:content_type => :json}
      ))).to contain_exactly({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND},
                 {"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})

      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})
      expect(JSON.parse(@client['/sh_job_wait2_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})

      expect(JSON.parse(@client_auth['/sh_job_wait1_2015-04-01'].patch(
        JSON.generate({:state => Patriot::JobStore::JobState::WAIT, :option => { :with_subsequent => false }}),
        {:content_type => :json}
      ))).to contain_exactly({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})

      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
      expect(JSON.parse(@client['/sh_job_wait2_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})

      expect(JSON.parse(@client_auth['/sh_job_wait2_2015-04-01'].patch(
        JSON.generate({:state => Patriot::JobStore::JobState::WAIT, :option => { :with_subsequent => false }}),
        {:content_type => :json}
      ))).to eq([{"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT}])

      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
      expect(JSON.parse(@client['/sh_job_wait2_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
    end


    it "should change the status of a set of jobs" do
      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
      expect(JSON.parse(@client['/sh_job_wait2_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})

      expect(JSON.parse(@client_auth['/'].patch(
        JSON.generate({:job_ids => ["sh_job_wait1_2015-04-01", "sh_job_wait2_2015-04-01"],
                       :state => Patriot::JobStore::JobState::SUSPEND}),
        {:content_type => :json}
      ))).to eq([{"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND},
                 {"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND}])

      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})
      expect(JSON.parse(@client['/sh_job_wait2_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::SUSPEND})

      expect(JSON.parse(@client_auth['/'].patch(
        JSON.generate({:job_ids => ["sh_job_wait1_2015-04-01", "sh_job_wait2_2015-04-01"],
                       :state => Patriot::JobStore::JobState::WAIT}),
        {:content_type => :json}
      ))).to contain_exactly({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT},
                 {"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})

      expect(JSON.parse(@client['/sh_job_wait1_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait1_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
      expect(JSON.parse(@client['/sh_job_wait2_2015-04-01'].get())
            ).to include({"job_id" => "sh_job_wait2_2015-04-01", "state" => Patriot::JobStore::JobState::WAIT})
    end


    it "should delete a job" do
      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT, :filter_exp => "%wait%"}}
      ))).to match_array([{"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait1_2015-04-01"},
                          {"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait2_2015-04-01"}])

      expect(JSON.parse(@client_auth['/sh_job_wait2_2015-04-01'].delete())
      ).to match_array({"job_id" => "sh_job_wait2_2015-04-01"})

      expect(JSON.parse(@client.get(
        {:params => {:state => Patriot::JobStore::JobState::WAIT, :filter_exp => "%wait%"}}
      ))).to match_array([{"state" => Patriot::JobStore::JobState::WAIT, "job_id" => "sh_job_wait1_2015-04-01"}])
    end


    it "should raise an error when calling get for detail with unexisting job_id" do
      expect{@client['/sh_never_match_2015-04-01'].get()
      }.to raise_error(RestClient::ResourceNotFound)
    end

    it "should raise an error when calling patch with unexisitng job_id" do
      expect{@client_auth['/sh_never_match_2015-04-01'].patch(
        JSON.generate({:state => Patriot::JobStore::JobState::SUSPEND}), {:content_type => :json}
      )}.to raise_error(RestClient::ResourceNotFound)
    end

    it "should raise an error when callind delete with unexisting job_id" do
      expect{@client_auth['/sh_never_match_2015-04-01'].delete()
      }.to raise_error(RestClient::ResourceNotFound)
    end


    it "should raise an error when calling post without auth" do
      expect{@client.post(
        JSON.generate({
          "COMMAND_CLASS" => "Patriot.Command.ShCommand",
          "name"          => "newjob"
        }),
        {:content_type => :json}
      )}.to raise_error(RestClient::Unauthorized)
    end

    it "should raise an error when calling patch without auth" do
      expect{@client['/sh_job_wait1_2015-04-01'].patch(
        JSON.generate({:state => Patriot::JobStore::JobState::SUSPEND}), {:content_type => :json}
      )}.to raise_error(RestClient::Unauthorized)
    end

    it "should raise an error when calling delete without auth" do
      expect{@client['/sh_job_wait2_2015-04-01'].delete()}.to raise_error(RestClient::Unauthorized)
    end
  end
end
