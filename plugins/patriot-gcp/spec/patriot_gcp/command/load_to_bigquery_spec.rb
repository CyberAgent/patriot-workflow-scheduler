require "init_test"
require 'erb'
include Patriot::Command::Parser

describe PatriotGCP::Command::LoadToBigQueryCommand do  
  before :all do
    @target_datetime = DateTime.new(2011,12,12)
    @config = config_for_test
  end 

  it "should work" do
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
    cmd.execute
  end 

  it "should work without arbitrary parameters" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do
      inifile path_to_test_config('test-bigquery.ini')
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end
    cmd = cmd.build[0]
    cmd.execute
  end

  it "should work with an empty file" do
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

    cmd.configure
    cmd.execute
  end 

  it "should raise an error with ini(set:project_id) and pbc(set:none)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-with-project_id.ini')
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    expect{cmd.execute}.to raise_error(
      PatriotGCP::Command::LoadToBigQueryCommand::BigQueryException,
      "configuration for BigQuery is not enough."
    )
  end 

  it "should raise an error with ini(set:dataset) and pbc(set:none)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-with-dataset.ini')
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    expect{cmd.execute}.to raise_error(
      PatriotGCP::Command::LoadToBigQueryCommand::BigQueryException,
      "configuration for BigQuery is not enough."
    )
  end 

  it "should raise an error with ini(set:none) and pbc(set:project_id)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-without-project_id-and-dataset.ini')
      project_id 'test-project'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    expect{cmd.execute}.to raise_error(
      PatriotGCP::Command::LoadToBigQueryCommand::BigQueryException,
      "configuration for BigQuery is not enough."
    )
  end 

  it "should raise an error with ini(set:none) and pbc(set:dataset)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-without-project_id-and-dataset.ini')
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    expect{cmd.execute}.to raise_error(
      PatriotGCP::Command::LoadToBigQueryCommand::BigQueryException,
      "configuration for BigQuery is not enough."
    )
  end 

  it "should raise an error with ini(set:none) and pbc(set:none)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-without-project_id-and-dataset.ini')
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    expect{cmd.execute}.to raise_error(
      PatriotGCP::Command::LoadToBigQueryCommand::BigQueryException,
      "configuration for BigQuery is not enough."
    )
  end 

  it "should work with ini(set:none) and pbc(set:project_id, dataset)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-without-project_id-and-dataset.ini')
      project_id 'test-project-pbc'
      dataset 'test-dataset-pbc'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    cmd.execute
    expect(cmd.instance_variable_get(:@project_id)).to eq('test-project-pbc')
    expect(cmd.instance_variable_get(:@dataset)).to eq('test-dataset-pbc')
  end 

  it "should work with ini(set:project_id, dataset) and pbc(set:none)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-with-project_id-and-dataset.ini')
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    cmd.execute
    expect(cmd.instance_variable_get(:@project_id)).to eq('test-project')
    expect(cmd.instance_variable_get(:@dataset)).to eq('test-dataset')
  end 

  it "should work with ini(set:project_id) and pbc(set:dataset)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-with-project_id.ini')
      dataset 'test-dataset-pbc'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    cmd.execute
    expect(cmd.instance_variable_get(:@project_id)).to eq('test-project')
    expect(cmd.instance_variable_get(:@dataset)).to eq('test-dataset-pbc')
  end 

  it "should work with ini(set:dataset) and pbc(set:project_id)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-with-dataset.ini')
      project_id 'test-project-pbc'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    cmd.execute
    expect(cmd.instance_variable_get(:@project_id)).to eq('test-project-pbc')
    expect(cmd.instance_variable_get(:@dataset)).to eq('test-dataset')
  end 

  it "should have priority in pbc settings with ini(set:project_id, dataset) and pbc(set:project_id, dataset)" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery-with-project_id-and-dataset.ini')
      project_id 'test-project-pbc'
      dataset 'test-dataset-pbc'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
    end 
    cmd = cmd.build[0]
    cmd.execute
    expect(cmd.instance_variable_get(:@project_id)).to eq('test-project-pbc')
    expect(cmd.instance_variable_get(:@dataset)).to eq('test-dataset-pbc')
  end 

  it "should raise an error when the given file doesn't exist" do
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
    expect{cmd.execute}.to raise_error(Exception, "The given file doesn't exist.")
  end 

  it "should raise an error when the ini file doesn't exist" do
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
    expect{cmd.build[0]}.to raise_error(Exception, "inifile not found")
  end 
end
