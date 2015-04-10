require 'init_test'
describe Patriot::Util::CronFormatParser do 

  include Patriot::Util::CronFormatParser 

  describe "expand_on_date" do 
    it "should expand hours" do 
      expanded = expand_on_date(Date.new(2013,8,1), "30 * * * *")
      expanded.should be_a_kind_of Array
      expanded.size.should == 24
      (0..23).each do |h|
        expanded.should include DateTime.new(2013,8,1,h,30,0)
      end
    end
    
    it "should expand hours and minites" do 
      expanded = expand_on_date(Date.new(2013,8,1), "*/15 * * * *")
      expanded.should be_a_kind_of Array
      expanded.size.should == 96
      (0..23).each do |h|
        [0,15,30,45].each do |m|
          expanded.should include DateTime.new(2013,8,1,h,m,0)
        end
      end
    end
  end

  describe "target_hours" do 
    it "should return all hours" do 
      hs = target_hours("*")
      hs.should be_a_kind_of Array
      hs.size.should == 24
      (0..23).each{|i| hs.should include i}
    end

    it "should handle interval" do 
      hs = target_hours("*/2")
      hs.should be_a_kind_of Array
      hs.size.should == 12
      (0..23).step(2).each{|i| hs.should include i}
    end

    it "should handle range" do 
      hs = target_hours("1-10")
      hs.should be_a_kind_of Array
      hs.size.should == 10
      (1..10).each{|i| hs.should include i}

      # with interval
      hs = target_hours("1-10/3")
      hs.should be_a_kind_of Array
      hs.size.should == 4
      [1,4,7,10].each{|i| hs.should include i}
    end

    it "should handle comma separated value" do 
      hs = target_hours("1,2,3,5,8")
      hs.should be_a_kind_of Array
      hs.size.should == 5
      [1,2,3,5,8].each{|i| hs.should include i}

      # with range
      hs = target_hours("1-3,5,8")
      hs.should be_a_kind_of Array
      hs.size.should == 5
      [1,2,3,5,8].each{|i| hs.should include i}
    end
  end
end
