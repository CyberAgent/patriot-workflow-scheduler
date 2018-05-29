require "init_test"
require 'erb'
include Patriot::Command::Parser

describe PatriotGCP::Command::BQCommand do
  before :all do
    @target_datetime = DateTime.new(2011,12,12)
    @config = config_for_test
  end

  describe 'job_id' do
    it 'should get job_id' do
      cmd = new_command(PatriotGCP::Command::BQCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        project_id 'test-project-id'
        name_suffix "job-id-test_#{_date_}"
        statement 'statement for test'
      end
      cmd = cmd.build[0]

      expect(cmd.job_id).to eq('bq_test-project-id_job-id-test_2011-12-12')
    end

    it 'should raise ArgumentError when only _date_ is set to name_suffix' do
      cmd = new_command(PatriotGCP::Command::BQCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        project_id 'test-project-id'
        name_suffix _date_
        statement 'statement for test'
      end

      expect { cmd.build[0] }.to raise_error(
        ArgumentError,
        'To set _date_ only is not allowed here to avoid job name duplication.'
      )
    end
  end

  describe 'configure' do
    it 'should raise an error when inifile is not set' do
      cmd = new_command(PatriotGCP::Command::BQCommand) do
        project_id 'test-project-id'
        name_suffix "job-id-test_#{_date_}"
        statement 'statement for test'
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : inifile= (PatriotGCP::Command::BQCommand)'
      )
    end

    it 'should raise an error when project_id is not set' do
      cmd = new_command(PatriotGCP::Command::BQCommand) do
        inifile path_to_test_config('test-bigquery.ini')
        name_suffix "job-id-test_#{_date_}"
        statement 'statement for test'
      end
      expect { cmd.build[0] }.to raise_error(
        RuntimeError,
        'validation error : project_id= (PatriotGCP::Command::BQCommand)'
      )
    end
  end

  it "should work" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq)
    cmd = new_command(PatriotGCP::Command::BQCommand) do
      inifile path_to_test_config('test-bigquery.ini')
      project_id 'test-project-id'
      name_suffix "job-id-test_#{_date_}"
      statement 'statement for test'
    end
    cmd = cmd.build[0]
    cmd.execute
  end

  it "should raise an error when the ini file doesn't exist" do
    allow_any_instance_of(PatriotGCP::Ext::BigQuery).to receive(:bq)
    cmd = new_command(PatriotGCP::Command::BQCommand) do
      inifile 'UNEXIST FILE'
      project_id 'test-project-id'
      name_suffix "job-id-test_#{_date_}"
      statement 'statement for test'
    end
    cmd = cmd.build[0]

    expect { cmd.execute }.to raise_error(Exception, 'inifile not found')
  end
end
