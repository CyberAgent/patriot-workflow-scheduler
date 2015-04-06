require 'init_test'

describe Patriot::Util::Script do 
  include Patriot::Util::Script

  ## グローバル変数の保護
  before :all do
    @original_dt = $dt
  end
  after :all do
    $dt = @original_dt
  end

  describe "get_batch_files" do
    context "all" do
      it "should be expected" do
        path    = "#{$ROOT_PATH}/spec/pbc/sh"
        date    = '2013-01-01'
        options = {:all => true}
        files   = get_batch_files(path, date, options)
        expect(files).to be_a Array
        expect(files.size).to eq 3
      end
    end

    context "daily" do
      it "should be expected" do
        path    = "#{$ROOT_PATH}/spec/pbc/sh/daily"
        date    = '2013-01-01'
        options = {:all => true}
        files   = get_batch_files(path, date, options)
        expect(files).to be_a Array
        expect(files.size).to eq 1
      end
    end

    context "weekly" do
      it "should be expected" do
        path    = "#{$ROOT_PATH}/spec/pbc/sh/weekly"
        date    = '2013-01-01'
        files   = get_batch_files(path, date)
        expect(files).to be_a Array
        expect(files.size).to eq 0

        date    = '2013-01-07'
        files   = get_batch_files(path, date)
        expect(files).to be_a Array
        expect(files.size).to eq 1
      end
    end

    context "monthly" do
      it "should be expected" do
        path    = "#{$ROOT_PATH}/spec/pbc/sh/monthly"
        date    = '2013-12-31'
        files   = get_batch_files(path, date)
        expect(files).to be_a Array
        expect(files.size).to eq 1

        date    = '2013-01-01'
        files   = get_batch_files(path, date)
        expect(files).to be_a Array
        expect(files.size).to eq 0
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
