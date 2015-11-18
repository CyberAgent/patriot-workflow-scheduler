module PatriotGCP
  module Command
    class LoadToBigQueryCommand < Patriot::Command::Base
      declare_command_name :load_to_bigquery
      include PatriotGCP::Ext::BigQuery

      command_attr :inifile, :dataset, :table, :schema, :options, :input_file, :name_suffix, :polling_interval

      class BigQueryException < Exception; end
      class GoogleCloudPlatformException < Exception; end

      def job_id
        job_id = "#{command_name}_#{@dataset}_#{@table}"
        job_id = "#{job_id}_#{@name_suffix}" unless @name_suffix.nil?
        return job_id
      end


      def execute
        @logger.info "start load_to_bigquery"

        unless File.exist?(@input_file)
          raise Exception, "The given file doesn't exist."
        end

        unless File.size?(@input_file)
          @logger.warn "The target file is empty"
          return
        end

        ini = IniFile.load(@inifile)
        if ini.nil?
          raise Exception, "inifile not found"
        end

        service_account = ini["gcp"]["service_account"]
        private_key = ini["gcp"]["private_key"]
        key_pass = ini["gcp"]["key_pass"]
        project_id = ini["bigquery"]["project_id"]

        if service_account.nil? or private_key.nil?
          raise GoogleCloudPlatformException, "configuration for GCP is not enough."
        elsif project_id.nil?
          raise BigQueryException, "configuration for BigQuery is not enough."
        end

        @logger.info "start uploading"
        stat_info = bq_load(@input_file,
                            private_key,
                            key_pass,
                            service_account,
                            project_id,
                            @dataset,
                            @table,
                            @schema,
                            @options,
                            @polling_interval)

        @logger.info "upload succeeded: #{stat_info}"
        @logger.info "end load_to_bigquery"
      end
    end
  end
end
