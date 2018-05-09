module PatriotGCP
  module Command
    class LoadToBigQueryCommand < Patriot::Command::Base
      declare_command_name :load_to_bigquery
      include PatriotGCP::Ext::BigQuery

      command_attr :inifile, :project_id, :dataset, :table, :schema, :options, :input_file, :name_suffix, :polling_interval
      validate_existence :inifile, :project_id, :dataset, :table

      class BigQueryException < Exception; end
      class GoogleCloudPlatformException < Exception; end

      def job_id
        "#{command_name}_#{@project_id}_#{@dataset}_#{@table}_#{@name_suffix}"
      end

      # @see Patriot::Command::Base#configure
      def configure
        @name_suffix ||= _date_
        self
      end

      def execute
        @logger.info "start load_to_bigquery"

        ini = IniFile.load(@inifile)
        if ini.nil?
          raise Exception, "inifile not found"
        end

        bigquery_keyfile  = ini["gcp"]["bigquery_keyfile"]

        unless File.exist?(@input_file)
          raise Exception, "The given file doesn't exist."
        end

        unless File.size?(@input_file)
          @logger.warn "The target file is empty"
          return
        end

        @logger.info "start uploading"
        stat_info = bq_load(@input_file,
                            bigquery_keyfile,
                            @project_id,
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
