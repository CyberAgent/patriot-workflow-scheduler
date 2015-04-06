require 'init_test'

describe Patriot::Util::Script do 
  include Patriot::Util::Retry
  include Patriot::Util::Logger

  before :all do
    @obj = ""
    @obj.extend(Patriot::Util::Retry)
    @obj.instance_variable_set(:@logger, create_logger(config_for_test))
    @retry_config = {:num_retry => 5, :wait_time => 0}
  end

  describe "execute_with_retry" do
    it "success" do
      times = 0
      block = Proc.new {times += 1; raise if times < 3}
      expect{@obj.send(:execute_with_retry, @retry_config, &block)}.not_to raise_error
      expect(times).to eq 3
    end

    it "fail" do
      times = 0
      block = Proc.new {times += 1; raise}
      expect{@obj.send(:execute_with_retry, @retry_config, &block)}.to raise_error
      expect(times).to eq 5
    end
  end

end
