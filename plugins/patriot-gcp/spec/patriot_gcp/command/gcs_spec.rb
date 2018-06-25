require "init_test"
require 'erb'
include Patriot::Command::Parser

describe PatriotGCP::Command::GCSCommand do
  before :all do
    @target_datetime = DateTime.new(2011,12,12)
    @config = config_for_test
  end

  describe 'job_id' do
    it 'should get job_id' do
      cmd = new_command(PatriotGCP::Command::GCSCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        project_id 'test-project-id'
        name_suffix "job-id-test_#{_date_}"
        bucket "test-bucket"
        command "create_file"
        source_file "source_file"
        dest_file "dest_file"
      end
      cmd = cmd.build[0]

      expect(cmd.job_id).to eq('gcs_create_file_test-project-id_test-bucket_job-id-test_2011-12-12')
    end

    it 'should raise ArgumentError when only _date_ is set to name_suffix' do
      cmd = new_command(PatriotGCP::Command::GCSCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        project_id 'test-project-id'
        name_suffix _date_
        bucket "test-bucket"
        command "create_file"
        source_file "source_file"
        dest_file "dest_file"
      end

      expect { cmd.build[0] }.to raise_error(
        ArgumentError,
        'To set _date_ only is not allowed here to avoid job name duplication.'
      )
    end
  end

  describe 'configure' do
    it 'should raise an error when inifile is not set' do
      cmd = new_command(PatriotGCP::Command::GCSCommand) do
        project_id 'test-project-id'
        name_suffix "job-id-test_#{_date_}"
        bucket "test-bucket"
        command "create_file"
        source_file "source_file"
        dest_file "dest_file"
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : inifile= (PatriotGCP::Command::GCSCommand)'
      )
    end

    it 'should raise an error when project_id is not set' do
      cmd = new_command(PatriotGCP::Command::GCSCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        name_suffix "job-id-test_#{_date_}"
        bucket "test-bucket"
        command "create_file"
        source_file "source_file"
        dest_file "dest_file"
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : project_id= (PatriotGCP::Command::GCSCommand)'
      )
    end
  end

  it "should work" do
    allow_any_instance_of(PatriotGCP::Ext::GCS).to receive(:gcs)
    cmd = new_command(PatriotGCP::Command::GCSCommand) do
      inifile path_to_test_config('test-bigquery.ini')
      project_id 'test-project-id'
      name_suffix "job-id-test_#{_date_}"
      bucket "test-bucket"
      command "create_file"
      source_file "source_file"
      dest_file "dest_file"
    end
    cmd = cmd.build[0]
    cmd.execute
  end

  it "should raise an error when the ini file doesn't exist" do
    allow_any_instance_of(PatriotGCP::Ext::GCS).to receive(:gcs)
    cmd = new_command(PatriotGCP::Command::GCSCommand) do
      inifile 'UNEXIST FILE'
      project_id 'test-project-id'
      name_suffix "job-id-test_#{_date_}"
      bucket "test-bucket"
      command "create_file"
      source_file "source_file"
      dest_file "dest_file"
    end
    cmd = cmd.build[0]

    expect { cmd.execute }.to raise_error(Exception, 'inifile not found')
  end
end
