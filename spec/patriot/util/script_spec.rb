require 'init_test'

describe Patriot::Util::Script do 
  include Patriot::Util::Script

  describe "get_batch_files" do
    context "all" do
      it "should be expected" do
        path    = "#{ROOT_PATH}/spec/pbc/interval"
        date    = '2013-01-01'
        options = {:all => true}
        files   = get_batch_files(path, date, options)
        expect(files).to be_a Array
        expect(files).to contain_exactly(
          *['', 'daily', 'monthly', 'weekly/1'].map{|f| File.join(path, f, 'sh.pbc')}
        )
      end
    end

    context "daily" do
      it "should not return weekly and monthly" do
        path    = "#{ROOT_PATH}/spec/pbc/interval"
        date    = '2013-01-01'
        files   = get_batch_files(path, date)
        expect(files).to be_a Array
        expect(files).to contain_exactly(
          *['', 'daily'].map{|f| File.join(path, f, 'sh.pbc')}
        )
      end
    end

    context "weekly" do
      it "should include a weekly file" do
        path    = "#{ROOT_PATH}/spec/pbc/interval"
        date    = '2013-01-07'
        files   = get_batch_files(path, date)
        expect(files).to be_a Array
        expect(files).to contain_exactly(
          *['', 'daily', 'weekly/1'].map{|f| File.join(path, f, 'sh.pbc')}
        )
      end
    end

    context "monthly" do
      it "should include a monthly file" do
        path    = "#{ROOT_PATH}/spec/pbc/interval"
        date    = '2013-12-31'
        files   = get_batch_files(path, date)
        expect(files).to be_a Array
        expect(files).to contain_exactly(
          *['', 'daily', 'monthly'].map{|f| File.join(path, f, 'sh.pbc')}
        )
      end
    end
  end

  describe 'target_options' do 
    it "should do nothing with :all" do
      expect(target_option('2013-05-13',{:all=>true})).to eq :all => true
    end

    it "should do ignore day" do
      actual = target_option('2013-05-13',{:day=>false})
      expect(actual[:day]).to eq false
      expect(actual[:month]).to eq false
      expect(actual[:week]).to eq 1
      actual = target_option('2013-04-30',{:day=>false})
      expect(actual[:day]).to eq false
      expect(actual[:month]).to eq true
      expect(actual[:week]).to eq 2
    end

    it "should do ignore month" do
      actual = target_option('2013-04-30',{:month=>false})
      expect(actual[:day]).to eq true
      expect(actual[:month]).to eq false
      expect(actual[:week]).to eq 2
    end

    it "should do ignore week" do
      actual = target_option('2013-04-30',{:week=>false})
      expect(actual[:day]).to eq true
      expect(actual[:month]).to eq true
      expect(actual[:week]).to eq false
    end
  end

end
