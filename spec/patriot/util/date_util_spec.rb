require 'init_test'
require 'patriot/util/date_util'

describe Patriot::Util::DateUtil do 
  include Patriot::Util::DateUtil

  describe "date_format" do
    it "should add day " do 
      val = date_format "2012-02-01", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:day =>1}
      expect(val).to eq "2012-02-02 23:12:34"
      val = date_format "2012-02-28", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:day =>1}
      expect(val).to eq "2012-02-29 23:12:34"
      val = date_format "2012-02-29", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:day =>1}
      expect(val).to eq "2012-03-01 23:12:34"
      val = date_format "2012-12-31", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:day =>1}
      expect(val).to eq "2013-01-01 23:12:34"
      val = date_format "2011-02-28", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:day =>1}
      expect(val).to eq "2011-03-01 23:12:34"
      val = date_format "2012-11-30", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:day =>1}
      expect(val).to eq "2012-12-01 23:12:34"
    end
    it "should add hour by date_format" do
      val = date_format "2012-02-01", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>1}
      expect(val).to eq "2012-02-02 00:12:34"
      val = date_format "2012-02-28", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>1}
      expect(val).to eq "2012-02-29 00:12:34"
      val = date_format "2012-02-29", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>1}
      expect(val).to eq "2012-03-01 00:12:34"
      val = date_format "2012-12-31", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>1}
      expect(val).to eq "2013-01-01 00:12:34"
      val = date_format "2011-02-28", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>1}
      expect(val).to eq "2011-03-01 00:12:34"
      val = date_format "2012-11-30", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>1}
      expect(val).to eq "2012-12-01 00:12:34"
    end

    it "should subtract hour by date_format" do
      val = date_format "2012-03-01", "00:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>-1}
      expect(val).to eq "2012-02-29 23:12:34"
      val = date_format "2013-03-01", "00:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>-1}
      expect(val).to eq "2013-02-28 23:12:34"
      val = date_format "2012-01-01", "00:12:34" , "%Y-%m-%d %H:%M:%S", {:hour =>-1}
      expect(val).to eq "2011-12-31 23:12:34"
    end

    it "should add month and hourby date_format" do
      val = date_format "2012-02-28", "23:12:34" , "%Y-%m-%d %H:%M:%S", {:month =>1, :hour =>1}
      expect(val).to eq "2012-03-29 00:12:34"
    end
  end

  it 'should be equal to values when adding to interval' do
    val = date_add("2013-01-01", 10)
    expect(val).to eq "2013-01-11"
    val = date_add("2013-01-01", -10)
    expect(val).to eq "2012-12-22"
  end

  it 'should be equal to values when subtracting interval' do
    val = date_sub("2013-01-01", 10)
    expect(val).to eq "2012-12-22"
    val = date_sub("2013-01-01", -10)
    expect(val).to eq "2013-01-11"
  end

  it "date=add=year" do
    val = date_add_year("2013-01-01", 1)
    expect(val).to eq "2014-01-01"
    val = date_add_year("2013-01-01", -2)
    expect(val).to eq "2011-01-01"
  end

  it "date_sub_year" do
    val = date_sub_year("2013-01-01", 1)
    expect(val).to eq "2012-01-01"
    val = date_sub_year("2013-01-01", -2)
    expect(val).to eq "2015-01-01"
  end

  it "month_add" do
    val = month_add("2012-12-23", 1)
    expect(val).to eq "2013-01"
    val = month_add("2012-12-23", -13)
    expect(val).to eq "2011-11"
  end

  it "month_sub" do
    val = month_sub("2012-12-23", 1)
    expect(val).to eq "2012-11"
    val = month_sub("2012-12-23", -13)
    expect(val).to eq "2014-01"
  end

  it "to_month" do
    val = to_month("2013-02-28")
    expect(val).to eq "2013-02"
  end

  it "to_start_of_month" do
    val = to_start_of_month("2013-01-23")
    expect(val).to eq "2013-01-01"
    val = to_start_of_month("1-11-23")
    expect(val).to eq "0001-11-01"
  end

  it "to_end_of_month" do
    val = to_end_of_month("2013-02-27")
    expect(val).to eq "2013-02-28"
    val = to_end_of_month("2012-02-27")
    expect(val).to eq "2012-02-29"
    val = to_end_of_month("2000-02-27")
    expect(val).to eq "2000-02-29"
    val = to_end_of_month("1900-02-27")
    expect(val).to eq "1900-02-28"
  end

  it "to_end_of_last_month" do
    val = to_end_of_last_month("2013-01-23")
    expect(val).to eq "2012-12-31"
    val = to_end_of_last_month("2012-03-01")
    expect(val).to eq "2012-02-29"
  end

  it "days_of_week" do
    val = days_of_week("2013-01-01")
    expect(val).to eq 2
    val != '2'
  end

  it "days_of_month" do
    val = days_of_month("2012-02")
    expect(val).to eq [
        "2012-02-01", "2012-02-02", "2012-02-03", "2012-02-04", "2012-02-05",
        "2012-02-06", "2012-02-07", "2012-02-08", "2012-02-09", "2012-02-10",
        "2012-02-11", "2012-02-12", "2012-02-13", "2012-02-14", "2012-02-15",
        "2012-02-16", "2012-02-17", "2012-02-18", "2012-02-19", "2012-02-20",
        "2012-02-21", "2012-02-22", "2012-02-23", "2012-02-24", "2012-02-25",
        "2012-02-26", "2012-02-27", "2012-02-28", "2012-02-29",
      ]
  end

  it "days_of_month_until" do
    val = days_of_month_until("2013-02-27")
    expect(val).to eq [
        "2013-02-01", "2013-02-02", "2013-02-03", "2013-02-04", "2013-02-05",
        "2013-02-06", "2013-02-07", "2013-02-08", "2013-02-09", "2013-02-10",
        "2013-02-11", "2013-02-12", "2013-02-13", "2013-02-14", "2013-02-15",
        "2013-02-16", "2013-02-17", "2013-02-18", "2013-02-19", "2013-02-20",
        "2013-02-21", "2013-02-22", "2013-02-23", "2013-02-24", "2013-02-25",
        "2013-02-26", "2013-02-27", 
      ]
  end

  it "to_date_obj" do
    val = to_date_obj("2012-12-31")
    expect(val).to be_a Date
  end

  it "date_to_month" do
    val = date_to_month("2013-01-01")
    expect(val).to eq "2013-01"
  end

  it "hours" do
    val = hours
    expect(val).to eq [
        "00", "01", "02", "03", "04", "05", "06", "07", "08", "09",
        "10", "11", "12", "13", "14", "15", "16", "17", "18", "19",
        "20", "21", "22", "23"
      ]
  end

  describe "validate_and_parse_dates" do
    it "should be valid" do
      date       = '2013-01-01'
      validate_and_parse_dates(date)
    end
    it "should be invalid" do
      date = ''
      expect {validate_and_parse_dates(date)}.to raise_error
      date = '20130101'
      expect {validate_and_parse_dates(date)}.to raise_error
    end

    it "should handle range of date" do
      date = '2013-01-30,2013-02-01'
      dates = validate_and_parse_dates(date)
      expect(dates).to eq ['2013-01-30','2013-01-31','2013-02-01']
    end
  end

end
