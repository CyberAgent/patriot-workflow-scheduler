require "init_test"
require 'erb'
include Patriot::Command::Parser

describe PatriotGCP::Command::LoadToBigQueryCommand do  
  before :all do
    @target_datetime = DateTime.new(2011,12,12)
    @config = config_for_test
  end 

  it "sholud work" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery.ini')
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
      options 'fieldDelimiter' => '\t',
              'writeDisposition' => 'WRITE_APPEND',
              'allowLargeResults' => true
      polling_interval 30
    end 
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    cmd.execute
  end 

  it "sholud work without arbitrary parameters" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do
      inifile path_to_test_config('test-bigquery.ini')
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    cmd.execute
  end

  it "sholud work with an empty file" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery.ini')
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "empty_file.txt")
      options 'fieldDelimiter' => '\t',
              'writeDisposition' => 'WRITE_APPEND',
              'allowLargeResults' => true
    end 
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    cmd.execute
  end 

  it "sholud raise an error when the given file doesn't exist" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery.ini')
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file 'UNEXIST FILE'
      options 'fieldDelimiter' => '\t',
              'writeDisposition' => 'WRITE_APPEND',
              'allowLargeResults' => true
    end 
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    expect{cmd.execute}.to raise_error(Exception)
  end 

  it "sholud raise an error when the ini file doesn't exist" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile 'UNEXIST FILE'
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
      options 'fieldDelimiter' => '\t',
              'writeDisposition' => 'WRITE_APPEND',
              'allowLargeResults' => true
    end 
    cmd = cmd.build[0]
    cmd = cmd.to_job.to_command(@config)

    expect{cmd.execute}.to raise_error(Exception)
  end 
end
