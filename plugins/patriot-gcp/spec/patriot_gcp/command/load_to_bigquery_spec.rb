require "init_test"
require 'erb'
include Patriot::Command::Parser

describe PatriotGCP::Command::LoadToBigQueryCommand do
  before :all do
    @target_datetime = DateTime.new(2011,12,12)
    @config = config_for_test
  end 

  describe 'job_id' do
    it 'should get job_id' do
      cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        project_id 'test-project_id'
        dataset 'test-dataset'
        table 'test-table'
        schema 'field1'
        input_file File.join(SAMPLE_DIR, 'hive_result.txt')
        options 'fieldDelimiter' => '\t',
                'writeDisposition' => 'WRITE_APPEND',
                'allowLargeResults' => true
        polling_interval 30
      end
      cmd = cmd.build[0]

      expect(cmd.job_id).to eq('loadtobigquery_test-project_id_test-dataset_test-table_2011-12-12')
    end
  end

  describe 'configure' do
    it 'should raise an error when inifile is not set' do
      cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do
        project_id 'test-project_id'
        dataset 'test-dataset'
        table 'test-table'
        schema 'field1'
        input_file File.join(SAMPLE_DIR, 'hive_result.txt')
        options 'fieldDelimiter' => '\t',
                'writeDisposition' => 'WRITE_APPEND',
                'allowLargeResults' => true
        polling_interval 30
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : inifile= (PatriotGCP::Command::LoadToBigQueryCommand)'
      )
    end

    it 'should raise an error when project_id is not set' do
      cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        dataset 'test-dataset'
        table 'test-table'
        schema 'field1'
        input_file File.join(SAMPLE_DIR, 'hive_result.txt')
        options 'fieldDelimiter' => '\t',
                'writeDisposition' => 'WRITE_APPEND',
                'allowLargeResults' => true
        polling_interval 30
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : project_id= (PatriotGCP::Command::LoadToBigQueryCommand)'
      )
    end

    it 'should raise an error when dataset is not set' do
      cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        project_id 'test-project_id'
        table 'test-table'
        schema 'field1'
        input_file File.join(SAMPLE_DIR, 'hive_result.txt')
        options 'fieldDelimiter' => '\t',
                'writeDisposition' => 'WRITE_APPEND',
                'allowLargeResults' => true
        polling_interval 30
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : dataset= (PatriotGCP::Command::LoadToBigQueryCommand)'
      )
    end

    it 'should raise an error when table is not set' do
      cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        project_id 'test-project_id'
        dataset 'test-dataset'
        schema 'field1'
        input_file File.join(SAMPLE_DIR, 'hive_result.txt')
        options 'fieldDelimiter' => '\t',
                'writeDisposition' => 'WRITE_APPEND',
                'allowLargeResults' => true
        polling_interval 30
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : table= (PatriotGCP::Command::LoadToBigQueryCommand)'
      )
    end
  end

  it "should work" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery.ini')
      project_id 'test-project_id'
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
      project_id 'test-project_id'
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
      project_id 'test-project_id'
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

  it "should raise an error when the given file doesn't exist" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq_load)
    cmd = new_command(PatriotGCP::Command::LoadToBigQueryCommand) do  
      inifile path_to_test_config('test-bigquery.ini')
      project_id 'test-project_id'
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
      project_id 'test-project_id'
      dataset 'test-dataset'
      table 'test-table'
      schema 'field1'
      input_file File.join(SAMPLE_DIR, "hive_result.txt")
      options 'fieldDelimiter' => '\t',
              'writeDisposition' => 'WRITE_APPEND',
              'allowLargeResults' => true
    end 
    cmd = cmd.build[0]

    expect { cmd.execute }.to raise_error(Exception, 'inifile not found')
  end 
end
