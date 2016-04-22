module PatriotAWS
  module Command
    class S3Command < Patriot::Command::Base
      declare_command_name :s3
      include PatriotAWS::Ext::AWS

      command_attr :name, :name_suffix, :inifile,
                   :command, :src, :dest, :options

      MODE_UPLOAD_FROM_LOCAL_TO_S3 = :mode_upload_from_local_to_s3
      S3_PROTOCOLS = %w(s3 s3n s3a).freeze
      COMMAND_COPY = :copy
      S3_COMMANDS = [COMMAND_COPY].freeze

      def job_id
        job_id = "#{command_name}_#{@command}_#{@name}"
        job_id += "_#{@name_suffix}" if @name_suffix
        job_id
      end

      # @see Patriot::Command::Base#configure
      def configure
        self
      end

      def execute
        @logger.info "start s3 #{@command}"

        @options ||= {}
        @options = @options.symbolize_keys
        @options = _set_options(@inifile, @options)

        _check_attrs(@command, @options, @src, @dest)

        config_aws(@options)
        s3_cli = Aws::S3::Client.new

        case @command
        when COMMAND_COPY.to_s
          _copy(s3_cli, @src, @dest, @options)
        else
          # should not reach here because this check is already done
          # in configure
          raise Exception,
                'command is invalid. '\
                "supported commands are #{S3_COMMANDS.map(&:to_s)}"
        end
      end

      # @private
      # get inifile info and set options parameters
      # @param  String          inifile
      # @param  Hash            options
      # @return Hash            options
      def _set_options(inifile, options)
        if inifile
          ini = IniFile.load(inifile)
          raise Exception, 'inifile not found.' if ini.nil?

          options[:access_key_id] =
            ini['common']['access_key_id'] || ini['s3']['access_key_id']
          options[:secret_access_key] =
            ini['s3']['secret_access_key'] || ini['common']['secret_access_key']
          options[:region] ||=
            ini['s3']['region'] || ini['common']['region']
        end

        options[:cmd_opts] = {} if options[:cmd_opts].nil?
        options[:cmd_opts][:multipart_threshold] ||= 15_728_640

        options
      end
      private :_set_options

      # @private
      # check command_attr
      # @param  String          command
      # @param  Hash            options
      # @param  String          src
      # @param  String          dest
      def _check_attrs(command, options, src, dest)
        # check region
        raise Exception, 'region is not set.' if options[:region].nil?

        # check credentials
        if options[:access_key_id].nil?
          raise Exception, 'access_key_id is not set.'
        end
        if options[:secret_access_key].nil?
          raise Exception, 'secret_access_key is not set.'
        end

        # check command
        raise Exception, 's3 comamnd is not set.' if command.nil?

        # check command and resources
        case command
        when COMMAND_COPY.to_s
          raise Exception, 'src or dest are not set.' if src.nil? || dest.nil?

          # check target if file exists
          raise Exception, 'src file does not exist.' unless File.exist?(src)

          # check if file is not empty
          raise Exception, 'The target file is empty.' unless File.size?(src)
        else
          raise Exception,
                'command is invalid. '\
                "supported commands are #{S3_COMMANDS.map(&:to_s)}"
        end
      end
      private :_check_attrs

      # @private
      # copy file(s) between file and s3
      # @param  Aws::S3::Client s3_cli
      # @param  String          src
      # @param  String          dest
      # @param  Hash            options
      def _copy(s3_cli, src, dest, options)
        @logger.info "source is #{@src}"
        @logger.info "destination is #{@dest}"
        @logger.info "region is #{options[:region]}"

        path_info = {}
        # path_info is going to be like:
        # path_info = {
        #   "src"=>{
        #     "protocol"=>"file",
        #     "path"=>"/path/to/file"
        #   }
        #   "dest"=>{
        #     "protocol"=>"s3",
        #     "bucket"=>"bucket",
        #     "key"=>"test_key"
        #   }
        # }
        path_info['src'] = _path_info(src)
        path_info['dest'] = _path_info(dest)

        mode = _mode_of_copy(path_info)
        @logger.info "copy mode is #{mode}"

        if mode == MODE_UPLOAD_FROM_LOCAL_TO_S3
          _upload_from_local_to_s3(s3_cli, path_info, options)
        end
      end
      private :_copy

      # @private
      # get path information
      # @param  String  path
      # @return Hash {protocol: 'file', path: '/path/to/file'}
      #              or {protocol: 's3' or sth,, bucket: 'bucket', key: 'key'}
      def _path_info(path)
        path_info = {}
        path_info['protocol'], bucket_key =
          _divide_protocol_and_bucket_key(path)

        # path has no protocol
        if path_info['protocol'] == 'file' || bucket_key.nil?
          path_info['path'] = path_info['protocol']
          path_info['protocol'] = 'file'
        # path has a protocol
        elsif bucket_key
          path_info['bucket'], path_info['key'] =
            _divide_bucket_and_key(bucket_key)
          raise Exception, 's3 object key is not set' if path_info['key'].nil?
        else
          raise Exception, 's3 bucket and object key are not set'
        end

        path_info
      end
      private :_path_info

      # @private
      # get the mode of copy
      # only MODE_UPLOAD_FROM_LOCAL_TO_S3 is supported now
      # @param  Hash    path_info
      # @return Symbol
      def _mode_of_copy(path_info)
        # TODO: need to implement
        # MODE_UPLOAD_FROM_LOCAL_TO_S3
        # MODE_UPLOAD_FROM_HDFS_TO_S3
        # MODE_GET_FROM_S3_TO_LOCAL
        # MODE_GET_FROM_S3_TO_HDFS
        # MODE_COPY and
        # MODE_RECURSIVE_UPLOAD_FROM_LOCAL_TO_S3
        # MODE_RECURSIVE_UPLOAD_FROM_HDFS_TO_S3
        # puts path_info['src']['protocol']
        # puts path_info['dest']['protocol']
        # puts S3_PROTOCOLS
        # puts S3_PROTOCOLS.class
        # puts S3_PROTOCOLS.include?(path_info['dest']['protocol'])

        if path_info['src']['protocol'] == 'file' &&
           S3_PROTOCOLS.include?(path_info['dest']['protocol'])
          return MODE_UPLOAD_FROM_LOCAL_TO_S3
        else
          raise Exception,
                'only the mode to "copy" from local to s3 is supported now'
        end
      end
      private :_mode_of_copy

      # @private
      # upload file from local to s3
      # @param  Aws::S3::Client s3_cli
      # @param  Hash            path_info
      # @param  Hash            options
      def _upload_from_local_to_s3(s3_cli, path_info, options)
        @logger.info 'start uploading...'
        s3_resource = Aws::S3::Resource.new(client: s3_cli)
        obj = s3_resource
              .bucket(path_info['dest']['bucket'])
              .object(path_info['dest']['key'])

        obj.upload_file(
          path_info['src']['path'],
          options[:cmd_opts].symbolize_keys
        )
        @logger.info 'end upload'
      rescue Aws::S3::MultipartUploadError => errors
        puts "failed upload file to S3: #{errors.message}"
      end
      private :_upload_from_local_to_s3

      # @private
      # divide path into protocol and s3 bucket + key
      # @param  String  path
      # @return Array   [protocol, bucket + key]
      def _divide_protocol_and_bucket_key(path)
        path.split('://')
      end
      private :_divide_protocol_and_bucket_key

      # @private
      # divide s3 bucket + key into bucket and key
      # @param  String  bucket + key
      # @return Array   [bucket, key]
      def _divide_bucket_and_key(path)
        path.split('/', 2)
      end
      private :_divide_bucket_and_key
    end
  end
end
