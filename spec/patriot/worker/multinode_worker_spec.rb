require 'init_test'
require 'timeout'

describe  Patriot::Worker::MultiNodeWorker do
  before :each do 
    @config = config_for_test('worker')
  end
  
  describe "init_worker" do
    before :each do
      @worker = Patriot::Worker::MultiNodeWorker.new(@config)
      @job1 = TestEnvironment.build_job()
      @job2 = TestEnvironment.build_job()
      @update_id = Time.now.to_i
      @job_store = @worker.instance_variable_get(:@job_store)
      @job_store.register(@update_id, [@job1,@job2])
    end

    it "should work with one node" do
      config = config_for_test('worker', 'test.onenode')
      node = config.get("nodes")[0]
      worker = Patriot::Worker::MultiNodeWorker.new(config)
      worker.init_worker
      nodes = worker.instance_variable_get(:@nodes)
      expect(nodes).to be_a Hash
      expect(nodes.size).to eq 1
      expect(nodes['own'][:type]).to eq Patriot::Worker::MultiNodeWorker::OWN
      expect(nodes['own'][:threads]).to eq 2
      expect(nodes['own'][:queue]).to be_a Queue
      expect(nodes['own'][:queue].size).to eq 0
    end

    it "should initiate multiple nodes" do
      @worker.init_worker
      nodes = @worker.instance_variable_get(:@nodes)
      expect(nodes).to be_a Hash
      expect(nodes.size).to eq 2
      expect(nodes['any'][:type]).to eq Patriot::Worker::MultiNodeWorker::ANY
      expect(nodes['any'][:threads]).to eq 3
      expect(nodes['any'][:queue]).to be_a Queue
      expect(nodes['any'][:queue].size).to eq 0
      expect(nodes['own'][:type]).to eq Patriot::Worker::MultiNodeWorker::OWN
      expect(nodes['own'][:threads]).to eq 2
      expect(nodes['own'][:queue]).to be_a Queue
      expect(nodes['own'][:queue].size).to eq 0
    end
  end

  describe "run_worker" do
    context "when worker is active" do
      before :each do
        @update_id = Time.now.to_i
        @worker = Patriot::Worker::MultiNodeWorker.new(@config)
        @worker.init_worker
        @cycle = @worker.instance_variable_get(:@cycle)
        @job1 = TestEnvironment.build_job()
        @job2 = TestEnvironment.build_job()
        @job_store = @worker.instance_variable_get(:@job_store)
        @job_store.register(@update_id, [@job1,@job2])
      end

      it "execute run_worker" do
        allow(@job_store).to receive(:get_job_tickets).and_return([])
        @worker.instance_variable_set(:@status, Patriot::Worker::Status::SHUTDOWN)
        expect{Timeout::timeout(@cycle*2){ @worker.run_worker }}.not_to raise_error
      end

      it "should stop in case of any thread stopped" do
        je = double("job_ticket")
        allow(je).to receive(:job_id).and_return(nil)
        allow(je).to receive(:node).and_return(nil)
        allow(@job_store).to receive(:get_job_tickets).and_return([je])
        allow(@worker).to receive(:execute_job){ raise "failure"}
        @worker.instance_variable_set(:@status, Patriot::Worker::Status::ACTIVE)
        expect{Timeout::timeout(@cycle*2){ @worker.run_worker }}.not_to raise_error
      end

      it "should stop in case of any thread stopped" do
        @worker.instance_variable_set(:@status, Patriot::Worker::Status::SLEEP)
        expect{
          Timeout::timeout(@cycle*2){ @worker.run_worker }
        }.to raise_error(Timeout::Error)
      end
    end
  end

  describe "update_queue" do
    before :each do
      @update_id = Time.now.to_i
      @worker = Patriot::Worker::MultiNodeWorker.new(@config)
      @worker.init_worker
      @cycle = @worker.instance_variable_get(:@cycle)
      @job1 = TestEnvironment.build_job()
      @job2 = TestEnvironment.build_job()
      @job_store = @worker.instance_variable_get(:@job_store)
      @job_store.register(@update_id, [@job1,@job2])
    end

    it "should be success" do
      job_ticket1 = Patriot::JobStore::JobTicket.new(@job1.job_id, @update_id)
      job_ticket2 = Patriot::JobStore::JobTicket.new(@job2.job_id, @update_id,'own')
      jobs = [job_ticket1,job_ticket2]
      nodes = @worker.instance_variable_get(:@nodes)
      expect(nodes['any'][:queue].size).to eq 0
      expect(nodes['own'][:queue].size).to eq 0
      @worker.send(:update_queue, jobs)
      expect(nodes['any'][:queue].size).to eq 1
      expect(nodes['own'][:queue].size).to eq 1
    end
  end

  describe "status" do
    before :each do
      @worker = Patriot::Worker::MultiNodeWorker.new(@config)
      @worker.init_worker
    end

    it "should return status" do
      @worker.status = Patriot::Worker::Status::ACTIVE
      expect(@worker.status).to eq Patriot::Worker::Status::ACTIVE
      @worker.status = Patriot::Worker::Status::SLEEP
      expect(@worker.status).to eq Patriot::Worker::Status::SLEEP
      @worker.status = Patriot::Worker::Status::SHUTDOWN
      expect(@worker.status).to eq Patriot::Worker::Status::SHUTDOWN
    end
  end

  describe "create_thread" do

    RSpec::Matchers.define :same_ticket do |expected_ticket|
      match do |actual|
        expect(actual.job_id).to eq expected_ticket.job_id
        #expect(actual.node).to eq expected_ticket.node
      end
      failure_message do |actual|
        "expected '#{expected_ticket}' but '#{actual}'"
      end
    end

    it "should be success" do
      job1 = TestEnvironment.build_job()
      job2 = TestEnvironment.build_job()
      job_ticket1 = Patriot::JobStore::JobTicket.new(job1.job_id, job1.update_id)
      job_ticket2 = Patriot::JobStore::JobTicket.new(job2.job_id, job2.update_id,'own')
      queue = Queue.new
      worker = Patriot::Worker::MultiNodeWorker.new(@config)
      worker.instance_variable_set(:@status, Patriot::Worker::Status::ACTIVE)
      worker.send(:create_thread, 'any', 1, queue)
      expect(worker).to receive(:execute_job).with(same_ticket(job_ticket1))
      expect(worker).to receive(:execute_job).with(same_ticket(job_ticket2))
      queue.push(job_ticket1)
      queue.push(job_ticket2)
      queue.push(:TERM)
      Timeout::timeout(3){ sleep 1 while(queue.size > 0) }
    end

    it "should tolerate undefined description" do
      incomplete_cmd = Class.new(Patriot::Command::Base) do
        def job_id
          "TEST"
        end
        def execute
          puts "incomplete"
        end
      end.new(@config)
      job1 = TestEnvironment.build_job()
      job_ticket1 = Patriot::JobStore::JobTicket.new(job1.job_id, job1.update_id)
      queue = Queue.new
      worker = Patriot::Worker::MultiNodeWorker.new(@config)
      worker.instance_variable_set(:@status, Patriot::Worker::Status::ACTIVE)
      jobstore = worker.instance_variable_get(:@job_store)
      allow(jobstore).to receive(:offer_to_execute).and_return({:command => incomplete_cmd})
      allow(jobstore).to receive(:report_completion_status)
      worker.send(:create_thread, 'any', 1, queue)
      queue.push(job_ticket1)
      queue.push(:TERM)
      Timeout::timeout(3){ sleep 1 while(queue.size > 0) }
    end
  end
end
