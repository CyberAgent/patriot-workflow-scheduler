require "init_test"

describe PatriotHadoop::Command::HiveCommand do
  include Patriot::Command::Parser

  before :all do
    @target_datetime = DateTime.new(2011,12,12)
    @config = config_for_test
  end

  it "sholud execute hive query" do
    query = 'select count(1) from tmp where dt = \'2011-12-12\' and dev = \'test\''
    cmd = new_command(PatriotHadoop::Command::HiveCommand) do
      hive_ql query
      output_prefix File.join(SAMPLE_DIR, "hive_result")
    end
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    allow(Dir).to receive(:exist?).and_return(true)
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:mkdir_p)
    allow_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)
    expect_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)\
                                                    .once\
                                                    .with(File.join(SAMPLE_DIR, "hive_result.hql"),
                                                          File.join(SAMPLE_DIR, "hive_result.tsv"),
                                                          nil)
    expect(File).to receive(:write).with(File.join(SAMPLE_DIR, "hive_result.hql"), query)
    cmd.execute
  end

  it "sholud execute hive query without output_prefix" do
    query = 'select count(1) from tmp where dt = \'2011-12-12\' and dev = \'test\''
    cmd = new_command(PatriotHadoop::Command::HiveCommand) do
      hive_ql query
      name_suffix 'test'
    end
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    allow(Dir).to receive(:exist?).and_return(true)
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:mkdir_p)
    allow_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)
    expect_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)\
                                                    .once\
                                                    .with("/tmp/hive_test.hql",
                                                          "/tmp/hive_test.tsv",
                                                          nil)
    expect(File).to receive(:write).with("/tmp/hive_test.hql", query)
    cmd.execute
  end

  it "sholud execute hive query with exec_user" do
    query = 'select count(1) from tmp where dt = \'2011-12-12\' and dev = \'test\''
    exec_user = 'user1'
    cmd = new_command(PatriotHadoop::Command::HiveCommand) do
      hive_ql query
      output_prefix File.join(SAMPLE_DIR, "hive_result")
      exec_user exec_user
    end
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    allow(Dir).to receive(:exist?).and_return(true)
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:mkdir_p)
    allow_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)
    expect_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)\
                                                    .once\
                                                    .with(File.join(SAMPLE_DIR, "hive_result.hql"),
                                                          File.join(SAMPLE_DIR, "hive_result.tsv"),
                                                          exec_user)
    expect(File).to receive(:write).with(File.join(SAMPLE_DIR, "hive_result.hql"), query)
    cmd.execute
  end

  it "sholud execute hive query with properties" do
    query = 'select count(1) from tmp where dt = \'2011-12-12\' and dev = \'test\''
    cmd = new_command(PatriotHadoop::Command::HiveCommand) do
      hive_ql query
      output_prefix File.join(SAMPLE_DIR, "hive_result")
      props 'hive.exec.reducers.max'=>'20',
            'hive.map.aggr' => 'true'
    end
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    allow(Dir).to receive(:exist?).and_return(true)
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:mkdir_p)
    allow_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)
    expect_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)\
                                                    .once\
                                                    .with(File.join(SAMPLE_DIR, "hive_result.hql"),
                                                          File.join(SAMPLE_DIR, "hive_result.tsv"),
                                                          nil)
    expect(File).to receive(:write).with(File.join(SAMPLE_DIR, "hive_result.hql"),
                                         "set hive.exec.reducers.max=20;set hive.map.aggr=true;" + query)
    cmd.execute
  end

  it "sholud execute hive query and the result is empty" do
    query = 'select count(1) from tmp where dt = \'2011-12-12\' and dev = \'test\''
    cmd = new_command(PatriotHadoop::Command::HiveCommand) do
      hive_ql query
      output_prefix File.join(SAMPLE_DIR, "hive_result_empty")
    end
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    allow(Dir).to receive(:exist?).and_return(true)
    allow(File).to receive(:write)
    allow(FileUtils).to receive(:mkdir_p)
    allow_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)
    expect_any_instance_of(PatriotHadoop::Ext::Hive).to receive(:execute_hivequery)\
                                                    .once\
                                                    .with(File.join(SAMPLE_DIR, "hive_result_empty.hql"),
                                                          File.join(SAMPLE_DIR, "hive_result_empty.tsv"),
                                                          nil)
    expect(File).to receive(:write).with(File.join(SAMPLE_DIR, "hive_result_empty.hql"), query)
    cmd.execute
  end

end
