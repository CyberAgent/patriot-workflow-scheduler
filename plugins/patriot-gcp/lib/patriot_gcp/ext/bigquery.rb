require 'google/api_client'
require 'patriot_gcp/version'


module PatriotGCP
  module Ext
    module BigQuery

      def self.included(cls)
        cls.send(:include, Patriot::Util::System)
      end

      class BigQueryException < Exception; end

      def _get_auth_client(p12_key, key_pass, email)
        key = Google::APIClient::KeyUtils.load_from_pkcs12(p12_key, key_pass)
        auth_client = Signet::OAuth2::Client.new(
            :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
            :audience => 'https://accounts.google.com/o/oauth2/token',
            :scope => 'https://www.googleapis.com/auth/bigquery',
            :issuer => email,
            :signing_key => key)
        auth_client.fetch_access_token!
        return auth_client
      end


      def _get_api_client()
        Google::APIClient.new(
            :application_name => VERSION::PROJECT_NAME,
            :application_version => VERSION::VERSION)
      end


      def _make_body(project_id, dataset_id, table_id, schema, options)
        body = {
          'configuration' => {
            'load' => {
              'schema' => schema,
              'destinationTable' => {
                'projectId' => project_id,
                'datasetId' => dataset_id,
                'tableId'   => table_id
              }
            }
          }
        }
        if options
          options.each{|key, value|
            body['configuration']['load'][key] = value
          }
        end

        return body
      end


      def _poll(bq_client,
                api_client,
                auth_client,
                project_id,
                job_id,
                polling_interval)

        polling_interval.times{
          response = JSON.parse(api_client.execute(
                                :api_method => bq_client.jobs.get,
                                :parameters => {
                                    'jobId' => job_id,
                                    'projectId' => project_id
                                },
                                :headers => {'Content-Type' => 'application/json; charset=UTF-8'},
                                :authorization => auth_client
                            ).response.body)
          state = response["status"]["state"]

          if state == 'DONE'
            if response["status"]["errors"]
              raise BigQueryException, "upload failed: #{response['status']['errors']}"
            else
              return response["statistics"]
            end
          end

          sleep 60
        }

        raise BigQueryException,"registered job didn't finish within: #{polling_interval} mins. please check if it will finish later on. jobId: #{job_id}"
      end


      def _bq_load(filename,
                   project_id,
                   dataset_id,
                   table_id,
                   auth_client,
                   api_client,
                   schema,
                   options,
                   polling_interval)

        bq_client = api_client.discovered_api('bigquery', 'v2')
        body = _make_body(project_id, dataset_id, table_id, schema, options)
        media = Google::APIClient::UploadIO.new(filename, "application/octet-stream")

        result = api_client.execute(
          :api_method => bq_client.jobs.insert,
          :parameters => {
            'projectId' => project_id,
            'uploadType' => 'multipart'
          },
          :body_object => body,
          :authorization => auth_client,
          :media => media
        )

        begin
          job_id = JSON.parse(result.response.body)['jobReference']['jobId']
        rescue
          raise BigQueryException, "failed to register job: #{result.response.body}"
        end

        return _poll(bq_client,
                     api_client,
                     auth_client,
                     project_id,
                     job_id,
                     polling_interval)
      end


      def bq_load(filename,
                  p12_key,
                  key_pass,
                  email,
                  project_id,
                  dataset_id,
                  table_id,
                  schema,
                  options=nil,
                  polling_interval=nil)

        options ||= {}
        polling_interval ||= 60

        api_client  = _get_api_client()
        auth_client = _get_auth_client(p12_key, key_pass, email)

        return _bq_load(filename,
                        project_id,
                        dataset_id,
                        table_id,
                        auth_client,
                        api_client,
                        schema,
                        options,
                        polling_interval)
      end

    end
  end
end
