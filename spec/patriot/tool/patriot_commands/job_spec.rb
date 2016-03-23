require 'init_test'

describe Patriot::Tool::PatriotCommands::Job do
  before :each do
    @job_store = Patriot::JobStore::InMemoryStore.new("shared", config_for_test)
    allow(Patriot::JobStore::Factory).to receive(:create_jobstore).and_return(@job_store)
    allow(Patriot::JobStore::InMemoryStore).to receive(:new).and_return(@job_store)
  end

  describe "delete" do

    it "should delete a job" do
      args = ['job', "--config=#{path_to_test_config}", 'delete', 'job_id']
      expect(@job_store).to receive(:delete_job).with("job_id")
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end

    it "should delete jobs" do
      args = ['job', "--config=#{path_to_test_config}", 'delete', 'job_id1', 'job_id2']
      expect(@job_store).to receive(:delete_job).with("job_id1")
      expect(@job_store).to receive(:delete_job).with("job_id2")
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
    end
  end

  describe "show valid dependency" do
    before :each do
      @update_id = Time.now.to_i
      @p_job = TestEnvironment.build_job({:produce => ['p1']})
      @m_job = TestEnvironment.build_job({:require => ['p1'], :produce => ['p2']})
      @c_job = TestEnvironment.build_job({:require => ['p2']})
      @illegal_job = TestEnvironment.build_job({:require => ['illegal']})
      @job_store.register(@update_id, [@p_job, @m_job, @c_job, @illegal_job])
    end

    it "should show dependency" do
      args = ["job", "--config=#{path_to_test_config}", "show_dependency", @m_job.job_id]
      $stdout = StringIO.new
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect($stdout.string).to eq <<"EOS"
#{@m_job.job_id}
  <= p1 = #{@p_job.job_id}, 1
EOS

      args = ["job", "--config=#{path_to_test_config}", "show_dependency", @c_job.job_id]
      $stdout = StringIO.new
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect($stdout.string).to eq <<"EOS"
#{@c_job.job_id}
  <= p2 = #{@m_job.job_id}, 1
    <= p1 = #{@p_job.job_id}, 1
EOS
    end
  end

  describe "show incorrect dependency" do
    before :each do
      @update_id = Time.now.to_i
      @p_job = TestEnvironment.build_job({:produce => ['p1']})
      @m_job = TestEnvironment.build_job({:require => ['p1'], :produce => ['p2']})
      @c_job = TestEnvironment.build_job({:require => ['p2']})
      @illegal_job = TestEnvironment.build_job({:require => ['illegal']})
      @job_store.register(@update_id, [@p_job, @m_job, @c_job, @illegal_job])
      allow(@job_store).to receive(:get).and_call_original
      allow(@job_store).to receive(:get).with(anything, {:include_dependency => true}).and_return({:consumers => {}, :producers => {}})
    end

    it "should show corrupted dependency" do
      args = ["job", "--config=#{path_to_test_config}", "show_dependency", @m_job.job_id]
      $stdout = StringIO.new
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect($stdout.string).to eq <<"EOS"
#{@m_job.job_id}
  <= p1 = WARN: currupted dependency #{@p_job.job_id}, 1
EOS

      args = ["job", "--config=#{path_to_test_config}", "show_dependency", @c_job.job_id]
      $stdout = StringIO.new
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect($stdout.string).to eq <<"EOS"
#{@c_job.job_id}
  <= p2 = WARN: currupted dependency #{@m_job.job_id}, 1
    <= p1 = WARN: currupted dependency #{@p_job.job_id}, 1
EOS
    end

    it "should show illegal dependency" do
      args = ["job", "--config=#{path_to_test_config}", "show_dependency", @illegal_job.job_id]
      $stdout = StringIO.new
      expect{Patriot::Tool::PatriotCommand.start(args)}.not_to raise_error
      expect($stdout.string).to eq <<"EOS"
#{@illegal_job.job_id}
  <= illegal = WARN: no producer exists
EOS
    end
  end
end
