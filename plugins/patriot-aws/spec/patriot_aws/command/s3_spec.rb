require 'init_test'
require 'rspec/mocks/standalone'
include Patriot::Command::Parser

describe PatriotAWS::Command::S3Command do
  before :all do
    @target_datetime = DateTime.new(2011, 12, 12)
    @config = config_for_test

    @s3_cli = Aws::S3::Client.new(stub_responses: true)
    allow(Aws::S3::Client).to receive(:new).and_return(@s3_cli)

    @s3_resource = Aws::S3::Resource.new(stub_responses: true)
    allow(Aws::S3::Resource).to receive(:new).and_return(@s3_resource)
  end

  describe 'job_id' do
    it 'should get job_id' do
      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        name_suffix _date_
        command 'copy'
      end
      cmd = cmd.build[0]

      expect(cmd.job_id).to eq('s3_copy_test_s3_2011-12-12')
    end
  end

  describe 'execute' do
    it 'should cause an error "inifile not found."' do
      inifile = path_to_test_config('NOT_EXIST')
      options = { region: 'ccc' }

      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        inifile inifile
        command 'copy'
        options options
        src File.join(SAMPLE_DIR, 'sample.txt')
        dest 's3://bucket/test_object'
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        'inifile not found.'
      )
    end

    it 'should cause an error "region is not set."' do
      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        inifile path_to_test_config('test-aws-with-credentials.ini')
        command 'copy'
        src File.join(SAMPLE_DIR, 'sample.txt')
        dest 's3://bucket/test_object'
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        'region is not set.'
      )
    end

    it 'should cause an error "access_key_id is not set."' do
      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        inifile path_to_test_config('test-aws-without-access_key_id.ini')
        command 'copy'
        options region: 'ccc'
        src File.join(SAMPLE_DIR, 'sample.txt')
        dest 's3://bucket/test_object'
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        'access_key_id is not set.'
      )
    end

    it 'should cause an error "secret_access_key is not set."' do
      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        inifile path_to_test_config('test-aws-without-secret_access_key.ini')
        command 'copy'
        options region: 'ccc'
        src File.join(SAMPLE_DIR, 'sample.txt')
        dest 's3://bucket/test_object'
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        'secret_access_key is not set.'
      )
    end

    it 'should cause an error "s3 comamnd is not set."' do
      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        inifile path_to_test_config('test-aws-with-credentials.ini')
        options region: 'ccc'
        src File.join(SAMPLE_DIR, 'sample.txt')
        dest 's3://bucket/test_object'
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        's3 comamnd is not set.'
      )
    end

    it 'should cause an error "command is invalid. supported commands are '\
       '#{S3_COMMANDS}"' do
      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        inifile path_to_test_config('test-aws-with-credentials.ini')
        command 'NOT_EXIST'
        options region: 'ccc'
        src File.join(SAMPLE_DIR, 'empty_file.txt')
        dest 's3://bucket/test_object'
      end
      cmd = cmd.build[0]

      expect { cmd.execute }.to raise_error(
        Exception,
        'command is invalid. supported commands are '\
        "#{PatriotAWS::Command::S3Command::S3_COMMANDS.map(&:to_s)}"
      )
    end

    describe 'command copy' do
      it 'should work with inifile' do
        inifile = path_to_test_config('test-aws-with-credentials-region.ini')
        src = File.join(SAMPLE_DIR, 'sample.txt')
        dest = 's3://bucket/test_object'
        options = {}

        cmd = new_command(PatriotAWS::Command::S3Command) do
          name 'test_s3'
          inifile inifile
          command 'copy'
          src src
          dest dest
        end
        cmd = cmd.build[0]

        merged_options = options.merge(
          access_key_id: 'aaa',
          secret_access_key: 'bbb',
          region: 'ccc',
          cmd_opts: { multipart_threshold: 15_728_640 }
        )

        expect(cmd).to receive(:_set_options).once.with(inifile, options)
          .and_return(merged_options)

        expect(cmd).to receive(:_check_attrs).once.with(
          'copy',
          merged_options,
          src,
          dest
        )

        expect(cmd).to receive(:config_aws).once.with(merged_options)

        expect(cmd).to receive(:_copy).once.with(
          @s3_cli,
          src,
          dest,
          merged_options
        )

        cmd.execute
      end

      it 'should work with inifile and region option in pbc' do
        inifile = path_to_test_config('test-aws-with-credentials.ini')
        src = File.join(SAMPLE_DIR, 'sample.txt')
        dest = 's3://bucket/test_object'
        options = {
          region: 'ccc'
        }

        cmd = new_command(PatriotAWS::Command::S3Command) do
          name 'test_s3'
          inifile inifile
          command 'copy'
          options options
          src src
          dest dest
        end
        cmd = cmd.build[0]

        merged_options = options.merge(
          access_key_id: 'aaa',
          secret_access_key: 'bbb',
          cmd_opts: { multipart_threshold: 15_728_640 }
        )

        expect(cmd).to receive(:_set_options).once.with(inifile, options)
          .and_return(merged_options)

        expect(cmd).to receive(:_check_attrs).once.with(
          'copy',
          merged_options,
          src,
          dest
        )

        expect(cmd).to receive(:config_aws).once.with(merged_options)

        expect(cmd).to receive(:_copy).once.with(
          @s3_cli,
          src,
          dest,
          merged_options
        )

        cmd.execute
      end

      it 'should work with multipart_threshold set' do
        inifile = path_to_test_config('test-aws-with-credentials.ini')
        src = File.join(SAMPLE_DIR, 'sample.txt')
        dest = 's3://bucket/test_object'
        options = {
          region: 'ccc',
          cmd_opts: { multipart_threshold: 10_000_000 }
        }

        cmd = new_command(PatriotAWS::Command::S3Command) do
          name 'test_s3'
          inifile inifile
          command 'copy'
          options options
          src src
          dest dest
        end
        cmd = cmd.build[0]

        merged_options = options.merge(
          access_key_id: 'aaa',
          secret_access_key: 'bbb'
        )

        expect(cmd).to receive(:_set_options).once.with(inifile, options)
          .and_return(merged_options)

        expect(cmd).to receive(:_check_attrs).once.with(
          'copy',
          merged_options,
          src,
          dest
        )

        expect(cmd).to receive(:config_aws).once.with(merged_options)

        expect(cmd).to receive(:_copy).once.with(
          @s3_cli,
          src,
          dest,
          merged_options
        )

        cmd.execute
      end

      it 'should cause an error "src or dest are not set."' do
        cmd = new_command(PatriotAWS::Command::S3Command) do
          name 'test_s3'
          inifile path_to_test_config('test-aws-with-credentials.ini')
          command 'copy'
          options region: 'ccc'
          dest 's3://bucket/test_object'
        end
        cmd = cmd.build[0]

        expect { cmd.execute }.to raise_error(
          Exception,
          'src or dest are not set.'
        )
      end

      it 'should cause an error "src or dest are not set."' do
        cmd = new_command(PatriotAWS::Command::S3Command) do
          name 'test_s3'
          inifile path_to_test_config('test-aws-with-credentials.ini')
          command 'copy'
          options region: 'ccc'
          src File.join(SAMPLE_DIR, 'sample.txt')
        end
        cmd = cmd.build[0]

        expect { cmd.execute }.to raise_error(
          Exception,
          'src or dest are not set.'
        )
      end

      it 'should cause an error "src file does not exist."' do
        cmd = new_command(PatriotAWS::Command::S3Command) do
          name 'test_s3'
          inifile path_to_test_config('test-aws-with-credentials.ini')
          command 'copy'
          options region: 'ccc'
          src 'NOT_EXIST'
          dest 's3://bucket/test_object'
        end
        cmd = cmd.build[0]

        expect { cmd.execute }.to raise_error(
          Exception,
          'src file does not exist.'
        )
      end

      it 'should cause an error "The target file is empty."' do
        cmd = new_command(PatriotAWS::Command::S3Command) do
          name 'test_s3'
          inifile path_to_test_config('test-aws-with-credentials.ini')
          command 'copy'
          options region: 'ccc'
          src File.join(SAMPLE_DIR, 'empty_file.txt')
          dest 's3://bucket/test_object'
        end
        cmd = cmd.build[0]

        expect { cmd.execute }.to raise_error(
          Exception,
          'The target file is empty.'
        )
      end
    end
  end

  describe '_copy' do
    it 'should work file as src and s3 as dest' do
      cmd = new_command(PatriotAWS::Command::S3Command) do
        name 'test_s3'
        inifile path_to_test_config('test-aws-with-credentials.ini')
        command 'copy'
        options region: 'ccc'
        src File.join(SAMPLE_DIR, 'sample.txt')
        dest 's3://bucket/test_object'
      end
      cmd = cmd.build[0]

      expect(cmd).to receive(:_path_info).exactly(2).times

      expect(cmd).to receive(:_mode_of_copy).once.and_return(
        PatriotAWS::Command::S3Command::MODE_UPLOAD_FROM_LOCAL_TO_S3
      )

      expect(cmd).to receive(:_upload_from_local_to_s3).once

      cmd.execute
    end
  end
end
