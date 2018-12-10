require 'init_test'
require 'erb'
include PatriotHadoop::Ext::Hive

HQL_FILE = "/path/to/tmpfile.hql"
OUTPUT_FILE = "/path/to/output.tsv"
OUTPUT_FILE_GZIP = "/path/to/output.tsv.gz"
OUTPUT_FILE_BZIP2 = "/path/to/output.tsv.bz2"
STATUS = "status"
SOUT = "stdout"
SERR = "stderr"

describe PatriotHadoop::Ext::Hive do
  before :each do 
    allow_any_instance_of(Patriot::Util::System).to receive(:execute_command).and_return(SOUT)
    allow(File).to receive(:rename)
    @config = config_for_test
  end

  describe "execute_hivequery" do
    it "should execute hivequery" do
      expect_any_instance_of(Patriot::Util::System).to receive(:execute_command).with("hive -f \"#{HQL_FILE}\"")
      expect(File).to receive(:rename).with(SOUT, OUTPUT_FILE)
      execute_hivequery(HQL_FILE, OUTPUT_FILE)
    end

    it "should execute hivequery with specific user" do
      exec_user = "user1"
      expect_any_instance_of(Patriot::Util::System).to receive(:execute_command).with("sudo -u #{exec_user} hive -f \"#{HQL_FILE}\"")
      expect(File).to receive(:rename).with(SOUT, OUTPUT_FILE)
      execute_hivequery(HQL_FILE, OUTPUT_FILE, exec_user)
    end

    it "should execute hivequery with gzip option" do
      expect_any_instance_of(Patriot::Util::System).to receive(:execute_command).with("hive -f \"#{HQL_FILE}\" | gzip --stdout --force")
      expect(File).to receive(:rename).with(SOUT, OUTPUT_FILE_GZIP)
      execute_hivequery(HQL_FILE, OUTPUT_FILE_GZIP)
    end

    it "should execute hivequery with specific user and gzip option" do
      exec_user = "user1"
      expect_any_instance_of(Patriot::Util::System).to receive(:execute_command).with("sudo -u #{exec_user} hive -f \"#{HQL_FILE}\" | gzip --stdout --force")
      expect(File).to receive(:rename).with(SOUT, OUTPUT_FILE_GZIP)
      execute_hivequery(HQL_FILE, OUTPUT_FILE_GZIP, exec_user)
    end

    it "should execute hivequery with bzip2 option" do
      expect_any_instance_of(Patriot::Util::System).to receive(:execute_command).with("hive -f \"#{HQL_FILE}\" | bzip2 --stdout --force")
      expect(File).to receive(:rename).with(SOUT, OUTPUT_FILE_BZIP2)
      execute_hivequery(HQL_FILE, OUTPUT_FILE_BZIP2)
    end

    it "should execute hivequery with specific user and bzip2 option" do
      exec_user = "user1"
      expect_any_instance_of(Patriot::Util::System).to receive(:execute_command).with("sudo -u #{exec_user} hive -f \"#{HQL_FILE}\" | bzip2 --stdout --force")
      expect(File).to receive(:rename).with(SOUT, OUTPUT_FILE_BZIP2)
      execute_hivequery(HQL_FILE, OUTPUT_FILE_BZIP2, exec_user)
    end

    it "should execute hivequery but raise an error" do
      allow_any_instance_of(Patriot::Util::System).to receive(:execute_command).and_yield(STATUS, SOUT, SERR)
      allow(File).to receive(:stat).and_return("stat")
      allow(File).to receive(:open)
      expect{execute_hivequery(HQL_FILE, OUTPUT_FILE)}.to raise_error(PatriotHadoop::Ext::Hive::HiveException)
    end
  end
end
