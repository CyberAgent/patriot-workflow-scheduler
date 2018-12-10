require 'google/cloud/bigquery'
require 'patriot_gcp/version'


module PatriotGCP
  module Ext
    module BigQuery

      def self.included(cls)
        cls.send(:include, Patriot::Util::System)
      end

      class BigQueryException < Exception; end

      def bq_load(filename,
                  bigquery_keyfile,
                  project_id,
                  dataset_id,
                  table_id,
                  schema,
                  options=nil,
                  polling_interval=nil)

        options ||= {}
        polling_interval ||= 60

        ENV['BIGQUERY_KEYFILE'] = bigquery_keyfile

        bigquery = Google::Cloud::Bigquery.new(
          project: project_id,
          retries: 3,
          timeout: polling_interval * 60
        )

        # exclude partition string
        # table_name$YYYYMMDD -> table_name
        original_table_id = table_id.split('$')[0]

        dataset = bigquery.dataset dataset_id
        table = dataset.table original_table_id

        if table.nil?
          # TODO: 
          # schemaとoptionがメソッドやその引数で指定されるようになっており、
          # 大幅な仕様変更となっているが、旧ライブラリ同様の設定を読み込めるよう
          # 議論されている。
          # https://github.com/GoogleCloudPlatform/google-cloud-ruby/issues/1919
          # 
          # こちらが対応された場合は下記ソースを変更する。
          dataset.create_table original_table_id do |updater|
            updater.schema do |scm|
              schema['fields'].each do |row|
                name = row['name']
                type = row['type'].downcase.to_sym
                mode = row['mode'].downcase.to_sym if row['mode']

                scm.method(type).call(name, mode: mode)
              end
            end
            # 取り込み時間分割テーブルに設定
            updater.time_partitioning_type = "DAY"
          end
        end

        job = dataset.load_job(
          table_id,
          filename,
          format: options['format'] || nil,
          quote: options['quote'] || nil,
          skip_leading: options['skipLeadingRows'] || nil,
          write: options['writeDisposition'] || nil,
          delimiter: options['fieldDelimiter'] || nil,
          null_marker: options['nullMarker'] || nil,
        )

        job.wait_until_done!

        if job.failed?
          raise BigQueryException, "upload failed: #{job.errors}"
        else
          return job.statistics
        end
      end

      def bq(bigquery_keyfile, project_id, statement)
        ENV['BIGQUERY_KEYFILE'] = bigquery_keyfile

        bigquery = Google::Cloud::Bigquery.new(
          project: project_id,
          retries: 3
        )

        job = bigquery.query_job statement

        job.wait_until_done!

        if job.failed?
          raise BigQueryException, "statement execution failed: #{job.errors}"
        else
          return job.statistics
        end
      end
    end
  end
end
