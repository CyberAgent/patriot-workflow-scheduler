require 'init_test'

describe Patriot::Util::DBClient::HashRecord do

  before :each do 
    @obj = Patriot::Util::DBClient::HashRecord.new({"attr1" => 1, "attr2" => "a"})
  end

  describe "getter" do
    it "should return value " do
      expect(@obj.attr1).to eq 1
      expect(@obj.attr2).to eq "a"
    end

    it "should not respond to unknown attribute " do
      expect(@obj).not_to respond_to(:attr3)
    end
  end

  describe "setter" do
    it "should store value " do
      @obj.attr1=2
      expect(@obj.attr1).to eq 2
      expect(@obj.instance_variable_get(:@record)[:attr1]).to eq 2
    end

  end

end
