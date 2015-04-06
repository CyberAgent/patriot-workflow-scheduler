require 'init_test'
require 'rspec'

describe Patriot::Util::System do
  include Patriot::Util::Logger
  before(:each) do
    @config = config_for_test
    @obj = Object.new
    @obj.extend(Patriot::Util::System)
    @obj.instance_variable_set(:@config, @config)
    logger = create_logger(@config)
    @obj.instance_variable_set(:@logger, logger)
  end

  describe ".tmp_dir" do
    it "should return a temporary file name" do
      value = @obj.tmp_dir(987, "2013-01-01", 1356966121)
      expect(value).to eq "#{Patriot::Util::System::DEFAULT_PATRIOT_TMP_DIR}/2013-01-01/p987_20130101_000201"
    end

    it "should return a configured temporary file name" do
      value = @obj.tmp_dir(987, "2013-01-01", 1356966121, "test_tmp_dir")
      expect(value).to eq "test_tmp_dir/2013-01-01/p987_20130101_000201"
    end
  end

  describe ".do_fork" do
    it "expect to raise error without variagle" do
      expect { @obj.do_fork() }.to raise_error(ArgumentError)
      expect { @obj.do_fork('echo 122333') }.to raise_error(ArgumentError)
      expect { @obj.do_fork('echo 122333', '2013-01-01') }.to raise_error(ArgumentError)
    end

    it "should be equal to what echo-command wrote down" do
      ## write results
      command = 'echo "test_output"'
      cid = @obj.do_fork(command, "2013-01-01", 1356966000)

      ## wait for ending fork process
      sleep 1

      ## match result content
      tmp_dir = @obj.tmp_dir(cid, "2013-01-01", 1356966000)
      files = Dir.glob("#{tmp_dir}/*.stdout")
      expect(files[0]).not_to be nil
      file = open(files[0], 'r')
      expect(file.read).to match(/test_output/m)
      file.close
    end
  end

  describe ".execute_command" do
    it "should railse error without arguments" do
      expect {@obj.execute_command}.to raise_error(ArgumentError)
    end
    it "should be equal to what echo-command wrote down" do
      ## write results
      command = 'echo ".execute_command"'
      stdout_file = @obj.execute_command(command)
      file = open(stdout_file, 'r')
      expect(file.read).to match(/\.execute_command/m)
      file.close
    end

    it "should not halt in case of a configured tmpdir" do
      allow(@config).to receive(:get).and_return(File.join("/tmp", "patriot_test"))
      command = 'echo ".execute_command"'
      stdout_file = Timeout::timeout(2){
        @obj.execute_command(command)
      }
      file = open(stdout_file, 'r')
      expect(file.read).to match(/\.execute_command/m)
      file.close
    end
  end
end
