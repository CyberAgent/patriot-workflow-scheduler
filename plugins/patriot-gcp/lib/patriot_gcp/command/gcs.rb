module PatriotGCP
  module Command
    class GCSCommand < Patriot::Command::Base
      declare_command_name :gcs
      include PatriotGCP::Ext::GCS

      command_attr :inifile, :project_id, :bucket, :command, :source_file, :dest_file, :name_suffix
      validate_existence :inifile, :project_id, :bucket, :command, :name_suffix

      class GCSException < Exception; end
      class GoogleCloudPlatformException < Exception; end

      def job_id
        "#{command_name}_#{@command}_#{@project_id}_#{@bucket}_#{@name_suffix}"
      end

      # @see Patriot::Command::Base#configure
      def configure
        if @name_suffix == _date_
          raise ArgumentError, 'To set _date_ only is not allowed here to avoid job name duplication.'
        end
        self
      end

      def execute
        @logger.info "start gcs #{@command}"

        ini = IniFile.load(@inifile)
        if ini.nil?
          raise Exception, "inifile not found"
        end

        gcs_keyfile  = ini["gcp"]["gcs_keyfile"]

        stat_info = gcs(
          gcs_keyfile,
          @project_id,
          @bucket,
          @command,
          @source_file,
          @dest_file
        )

        @logger.info "gcs #{@command} execution succeeded: #{stat_info}"
        @logger.info "end gcs #{@command}"
      end
    end
  end
end
