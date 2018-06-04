module PatriotGCP
  module Command
    class BQCommand < Patriot::Command::Base
      declare_command_name :bq
      include PatriotGCP::Ext::BigQuery

      command_attr :inifile, :project_id, :statement, :name_suffix
      validate_existence :inifile, :project_id, :statement, :name_suffix

      class BigQueryException < Exception; end
      class GoogleCloudPlatformException < Exception; end

      def job_id
        "#{command_name}_#{@project_id}_#{@name_suffix}"
      end

      # @see Patriot::Command::Base#configure
      def configure
        if @name_suffix == _date_
          raise ArgumentError, 'To set _date_ only is not allowed here to avoid job name duplication.'
        end
        @statement = eval_attr(@statement)
        self
      end

      def execute
        @logger.info "start bq"

        ini = IniFile.load(@inifile)
        if ini.nil?
          raise Exception, "inifile not found"
        end

        bigquery_keyfile  = ini["gcp"]["bigquery_keyfile"]

        stat_info = bq(
          bigquery_keyfile,
          @project_id,
          @statement
        )

        @logger.info "statement execution succeeded: #{stat_info}"
        @logger.info "end bq"
      end
    end
  end
end
