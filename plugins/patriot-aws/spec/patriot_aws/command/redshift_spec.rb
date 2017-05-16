require 'init_test'
require 'rspec/mocks/standalone'
include Patriot::Command::Parser

describe PatriotAWS::Command::RedshiftCommand do
  before :all do
    @target_datetime = DateTime.new(2017, 05, 15)
    @config = config_for_test
  end

  describe 'job_id' do
    it 'should get job_id' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        name_suffix 'name_suffix_test'
        inifile '/path/to//redshift.ini'
        query 'select * from test_table'
      end
      cmd = cmd.build[0]

      expect(cmd.job_id).to eq('redshift_test_redshift_name_suffix_test')
    end
  end

  describe 'configure' do
    it 'should set date if name_suffix is not passed' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile '/path/to//redshift.ini'
        query 'select * from test_table'
      end
      cmd = cmd.build[0]

      expect(cmd.job_id).to eq('redshift_test_redshift_2017-05-15')
    end
  end

  describe 'execute' do
    it 'should cause an error "inifile not found."' do
      inifile = path_to_test_config('NOT_EXIST')

      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile inifile
        query 'select * from test_table'
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        'inifile not found.'
      )
    end

    it 'should cause an error "query is not set."' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile path_to_test_config('test-redshift.ini')
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        'query is not set.'
      )
    end

    it 'should work with header and comma delimiter' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile path_to_test_config('test-redshift.ini')
        query 'select * from test_table'
        options :with_header => true, :delimiter => ","
      end
      cmd = cmd.build[0]

      expect(cmd).to receive(:_set_options).once

      stub_pg_conn = double
      allow(stub_pg_conn).to receive(:exec).once
        .with('select * from test_table')
        .and_return([
          {'no'=>1,'name'=>'name1'},
          {'no'=>2,'name'=>'name2'}
        ])
      allow(stub_pg_conn).to receive(:close).once

      expect(PG::Connection).to receive(:new).once.with(
        :host     => 'test_host',
        :user     => 'test_user',
        :password => 'test_password',
        :dbname   => 'test_dbname',
        :port     => '5439'
      ).and_return(stub_pg_conn)

      expect(cmd).to receive(:puts).once
        .with(<<EOS.gsub(/\n$/, '')
no,name
1,name1
2,name2
EOS
             )

      cmd.execute
    end

    it 'should work with header and tab delimiter' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile path_to_test_config('test-redshift.ini')
        query 'select * from test_table'
        options :with_header => true, :delimiter => "\t"
      end
      cmd = cmd.build[0]

      expect(cmd).to receive(:_set_options).once

      stub_pg_conn = double
      allow(stub_pg_conn).to receive(:exec).once
        .with('select * from test_table')
        .and_return([
          {'no'=>1,'name'=>'name1'},
          {'no'=>2,'name'=>'name2'}
        ])
      allow(stub_pg_conn).to receive(:close).once

      expect(PG::Connection).to receive(:new).once.with(
        :host     => 'test_host',
        :user     => 'test_user',
        :password => 'test_password',
        :dbname   => 'test_dbname',
        :port     => '5439'
      ).and_return(stub_pg_conn)

      expect(cmd).to receive(:puts).once
        .with(<<EOS.gsub(/\n$/, '')
no\tname
1\tname1
2\tname2
EOS
             )

      cmd.execute
    end

    it 'should work without header and comma delimiter' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile path_to_test_config('test-redshift.ini')
        query 'select * from test_table'
        options :with_header => false, :delimiter => ","
      end
      cmd = cmd.build[0]

      expect(cmd).to receive(:_set_options).once

      stub_pg_conn = double
      allow(stub_pg_conn).to receive(:exec).once
        .with('select * from test_table')
        .and_return([
          {'no'=>1,'name'=>'name1'},
          {'no'=>2,'name'=>'name2'}
        ])
      allow(stub_pg_conn).to receive(:close).once

      expect(PG::Connection).to receive(:new).once.with(
        :host     => 'test_host',
        :user     => 'test_user',
        :password => 'test_password',
        :dbname   => 'test_dbname',
        :port     => '5439'
      ).and_return(stub_pg_conn)

      expect(cmd).to receive(:puts).once
        .with(<<EOS.gsub(/\n$/, '')
1,name1
2,name2
EOS
             )

      cmd.execute
    end

    it 'should work without header and tab delimiter' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile path_to_test_config('test-redshift.ini')
        query 'select * from test_table'
        options :with_header => false, :delimiter => "\t"
      end
      cmd = cmd.build[0]

      expect(cmd).to receive(:_set_options).once

      stub_pg_conn = double
      allow(stub_pg_conn).to receive(:exec).once
        .with('select * from test_table')
        .and_return([
          {'no'=>1,'name'=>'name1'},
          {'no'=>2,'name'=>'name2'}
        ])
      allow(stub_pg_conn).to receive(:close).once

      expect(PG::Connection).to receive(:new).once.with(
        :host     => 'test_host',
        :user     => 'test_user',
        :password => 'test_password',
        :dbname   => 'test_dbname',
        :port     => '5439'
      ).and_return(stub_pg_conn)

      expect(cmd).to receive(:puts).once
        .with(<<EOS.gsub(/\n$/, '')
1\tname1
2\tname2
EOS
             )

      cmd.execute
    end

    it 'should work without options' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile path_to_test_config('test-redshift.ini')
        query 'select * from test_table'
      end
      cmd = cmd.build[0]

      stub_pg_conn = double
      allow(stub_pg_conn).to receive(:exec).once
        .with('select * from test_table')
        .and_return([
          {'no'=>1,'name'=>'name1'},
          {'no'=>2,'name'=>'name2'}
        ])
      allow(stub_pg_conn).to receive(:close).once

      expect(PG::Connection).to receive(:new).once.with(
        :host     => 'test_host',
        :user     => 'test_user',
        :password => 'test_password',
        :dbname   => 'test_dbname',
        :port     => '5439'
      ).and_return(stub_pg_conn)

      expect(cmd).to receive(:puts).once
        .with(<<EOS.gsub(/\n$/, '')
1\tname1
2\tname2
EOS
             )

      cmd.execute
    end

    it 'should work with copy query' do
      cmd = new_command(PatriotAWS::Command::RedshiftCommand) do
        name 'test_redshift'
        inifile path_to_test_config('test-redshift.ini')
        query <<-EOS
          COPY test_schema.test_table
          FROM 's3://path/to/file'
          ACCESS_KEY_ID '%{access_key_id}'
          SECRET_ACCESS_KEY '%{secret_access_key}'
          delimiter '\t'
          gzip
        EOS
      end
      cmd = cmd.build[0]

      stub_pg_conn = double
      allow(stub_pg_conn).to receive(:exec).once
        .with(<<-EOS
          COPY test_schema.test_table
          FROM 's3://path/to/file'
          ACCESS_KEY_ID 'test_access_key_id'
          SECRET_ACCESS_KEY 'test_secret_access_key'
          delimiter '\t'
          gzip
        EOS
       )
      allow(stub_pg_conn).to receive(:close).once

      expect(PG::Connection).to receive(:new).once.with(
        :host     => 'test_host',
        :user     => 'test_user',
        :password => 'test_password',
        :dbname   => 'test_dbname',
        :port     => '5439'
      ).and_return(stub_pg_conn)

      cmd.execute
    end
  end
end
