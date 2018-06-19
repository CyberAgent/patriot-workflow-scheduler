require "google/cloud/storage"
require 'patriot_gcp/version'


module PatriotGCP
  module Ext
    module GCS

      def self.included(cls)
        cls.send(:include, Patriot::Util::System)
      end

      class GCSException < Exception; end

      def gcs(gcs_keyfile, project_id, bucket, command, source_file, dest_file)
        ENV['GOOGLE_CLOUD_KEYFILE'] = gcs_keyfile

        storage = Google::Cloud::Storage.new(
          project: project_id,
          retries: 3, # default value
          timeout: 3600
        )

        bucket = storage.bucket bucket

        if command == 'create_file'
          bucket.create_file(source_file, dest_file)
        elsif command == 'download'
          file = bucket.file source_file

          if file.nil?
            raise GCSException, "File not found."
          end

          file.download dest_file
        elsif command == 'delete'
          file = bucket.file source_file

          if file.nil?
            @logger.info "File not found."
          else
            file.delete
          end
        end
      end
    end
  end
end
