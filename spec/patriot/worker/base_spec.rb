require 'init_test'

require 'patriot/worker'
require 'patriot/worker/base'

describe Patriot::Worker::Base do
  before :each do
    @worker_base = Patriot::Worker::Base.new(config_for_test)
    @job1 = TestEnvirionment.build_job
    @update_id = Time.now.to_i
    @job_store = @worker_base.instance_variable_get(:@job_store)
    @job_store.register(@update_id, [@job1])
  end

  describe "module functions" do
    it "should return pid file" do
      expect(Patriot::Worker.get_pid_file(config_for_test)).to eq File.join(ROOT_PATH, "run","patriot-worker_default.pid" )
    end
  end

  describe "start_worker" do
    context "DOWN worker exists" do
      it "should not raise error" do
        allow(@worker_base).to receive(:get_pid).and_return(-1)
        error = false
        begin
          @worker_base.start_worker
        rescue Exception => e
          puts e.message
          puts e.backtrace.inspect
          error = true
        end
        expect(error).to be false
      end
    end
  end

  describe "get_pid" do
    it "should respond to" do
      expect(@worker_base).to respond_to(:get_pid)
    end
  end


  describe "execute_job" do

    it "should be nil with invalid argument" do
      job_ticket = Patriot::JobStore::JobTicket.new("0", 0)
      result    = @worker_base.execute_job(job_ticket)
      expect(result).to eq Patriot::Command::ExitCode::SKIPPED
    end

    it "should be skipped" do
      job_ticket = Patriot::JobStore::JobTicket.new(@job1.job_id, 0)
      result    = @worker_base.execute_job(job_ticket)
      expect(result).to eq Patriot::Command::ExitCode::SKIPPED
    end

    it "shuld success executing job" do
      Thread.current[:name] = 'test_node'
      job_ticket = Patriot::JobStore::JobTicket.new(@job1.job_id, @update_id)
      result = @worker_base.execute_job(job_ticket)
      expect(result).not_to be false
      expect(@job1).to be_succeeded_in @worker_base.instance_variable_get(:@job_store)
      history = @job_store.get_execution_history(@job1.job_id)
      expect(history.size).to eq 1
      expect(history[0]).to a_hash_including(:job_id    => @job1.job_id,
                                             :node      => Thread.current[:name],
                                             :host      => `hostname`.chomp,
                                             :exit_code => Patriot::Command::ExitCode::SUCCEEDED)
      expect(history[0][:begin_at]).not_to be nil
      expect(history[0][:end_at]).not_to be nil
    end

    it "should retry and tolerate failure of set state" do
      config = config_for_test
      worker = Patriot::Worker::Base.new(config)
      job_store = worker.instance_variable_get(:@job_store)
      allow(job_store).to receive(:offer_to_execute).
        and_return({:execution_id => 1, :command => @job1.to_command(config)})
      retry_cnt = 0
      allow(job_store).to receive(:report_completion_status){
        retry_cnt = retry_cnt + 1
        raise "ERROR"
      }
      job_ticket = Patriot::JobStore::JobTicket.new(@job1.job_id, @update_id)
      result = worker.execute_job(job_ticket)
      expect(retry_cnt).to eq 3
      expect(result).to eq Patriot::Command::ExitCode::SUCCEEDED
    end
  end

  describe "status" do
    it "shluld respond to" do
      expect(@worker_base).to respond_to(:status)
    end
  end

end
