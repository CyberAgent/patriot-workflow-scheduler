require 'erb'
require 'init_test'

unless ENV['TEST_DBMS'].nil?
  erb = ERB.new(File.open(File.join(ROOT_PATH, 'spec', 'template', 'job_store_spec.erb')).read)
  init_conf_statement = '@config = config_for_test(nil, ENV["TEST_DBMS"])'
  job_store_class = 'Patriot::JobStore::RDBJobStore'
  eval erb.result(binding)

  describe Patriot::JobStore::RDBJobStore do

    include Patriot::JobStore::Factory
    include JobStoreMatcher

    before :all do
      @config = config_for_test(nil, ENV["TEST_DBMS"])
      @update_id = Time.now.to_i
      @job_store = Patriot::JobStore::RDBJobStore.new("root", @config)
    end

    it "should use strict datetime format" do
      target_datetime = TestEnvironment::TEST_TARGET_DATE.strftime("%Y-%m-%d")
      job  = TestEnvironment.build_job({:job_id => 'startafter_test'})
      job[Patriot::Command::START_DATETIME_ATTR] = Time.new(2010,1,31)
      expect_any_instance_of(Patriot::Util::DBClient::MySQL2Client).to receive(:do_insert).once.with(
        "INSERT INTO jobs (job_id,update_id,priority,state,start_after,node,host,content) VALUES ('sh_job_startafter_test_#{target_datetime}',#{@update_id},1,1,'2010-01-31 00:00:00',NULL,NULL,'{\\\"COMMAND_CLASS\\\":\\\"Patriot.Command.ShCommand\\\",\\\"connector\\\":\\\"&&\\\",\\\"commands\\\":[\\\"echo 1\\\"],\\\"name\\\":\\\"job_startafter_test\\\",\\\"name_suffix\\\":\\\"#{target_datetime}\\\"}')"
      ).and_return(100)
      allow_any_instance_of(Patriot::Util::DBClient::MySQL2Client).to receive(:do_insert)
      @job_store.register(@update_id,[job])
    end
  end
end

