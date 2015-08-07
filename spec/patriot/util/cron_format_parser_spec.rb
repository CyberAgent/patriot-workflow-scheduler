require 'init_test'
describe Patriot::Util::CronFormatParser do 

  include Patriot::Util::CronFormatParser 

  describe "expand_on_date" do 
    it "should expand hours" do 
      expanded = expand_on_date(Date.new(2013,8,1), "30 * * * *")
      expect(expanded).to be_a Array
      expect(expanded.size).to eq 24
      (0..23).each do |h|
        expect(expanded).to include Time.new(2013,8,1,h,30,0)
      end
    end
    
    it "should expand hours and minites" do 
      expanded = expand_on_date(Date.new(2013,8,1), "*/15 * * * *")
      expect(expanded).to be_a Array
      expect(expanded.size).to eq 96
      (0..23).each do |h|
        [0,15,30,45].each do |m|
          expect(expanded).to include Time.new(2013,8,1,h,m,0)
        end
      end
    end
  end

  describe "target_hours" do 
    it "should return all hours" do 
      hs = target_hours("*")
      expect(hs).to be_a Array
      expect(hs.size).to eq 24
      (0..23).each{|i| expect(hs).to include i}
    end

    it "should handle interval" do 
      hs = target_hours("*/2")
      expect(hs).to be_a Array
      expect(hs.size).to eq 12
      (0..23).step(2).each{|i| expect(hs).to include i}
    end

    it "should handle range" do 
      hs = target_hours("1-10")
      expect(hs).to be_a Array
      expect(hs.size).to eq 10
      (1..10).each{|i| expect(hs).to include i}

      # with interval
      hs = target_hours("1-10/3")
      expect(hs).to be_a Array
      expect(hs.size).to eq 4
      [1,4,7,10].each{|i| expect(hs).to include i}
    end

    it "should handle comma separated value" do 
      hs = target_hours("1,2,3,5,8")
      expect(hs).to be_a Array
      expect(hs.size).to eq 5
      [1,2,3,5,8].each{|i| expect(hs).to include i}

      # with range
      hs = target_hours("1-3,5,8")
      expect(hs).to be_a Array
      expect(hs.size).to eq 5
      [1,2,3,5,8].each{|i| expect(hs).to include i}
    end
  end
end
