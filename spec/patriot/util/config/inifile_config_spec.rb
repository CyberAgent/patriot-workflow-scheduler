require 'init_test'

describe Patriot::Util::Config::IniFileConfig do 
  before :all do 
    @config = config_for_test('worker')
  end

  describe "worker config" do
    it "sholud return variables" do
      expect(@config.get('notify_addr')).to eq 'test@test'
      expect(@config.get('none')).to be nil
    end

    it "should return read worker section" do
      expect(@config.get('nodes')).to contain_exactly("own","any")
    end

  end

end
