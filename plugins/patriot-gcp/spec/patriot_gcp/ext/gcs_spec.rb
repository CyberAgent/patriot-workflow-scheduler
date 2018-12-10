require 'init_test'
require 'erb'
include PatriotGCP::Ext::GCS


describe PatriotGCP::Ext::GCS do
  describe "gcs" do
    it "should upload file" do
      storage_mock  = double('Google::Cloud::Storage mock')
      bucket_mock   = double('Google::Cloud::Storage bucket mock')

      allow(Google::Cloud::Storage).to receive(:new).and_return(storage_mock)
      allow(storage_mock).to receive(:bucket).and_return(bucket_mock)
      allow(bucket_mock).to receive(:create_file)

      gcs(
        '/path/to/gcs_keyfile',
        'test-project',
        'test-bucket',
        'create_file',
        '/path/to/source_file',
        '/path/to/dest_file'
      )

      expect(ENV.fetch('GOOGLE_CLOUD_KEYFILE')).to eq('/path/to/gcs_keyfile')

      expect(Google::Cloud::Storage).to have_received(:new).with(
        project: 'test-project',
        retries: 3,
        timeout: 3600
      ).once
      expect(storage_mock).to have_received(:bucket).with('test-bucket').once
      expect(bucket_mock).to have_received(:create_file).with('/path/to/source_file', '/path/to/dest_file').once
    end

    it "should download file" do
      storage_mock  = double('Google::Cloud::Storage mock')
      bucket_mock   = double('Google::Cloud::Storage bucket mock')
      file_mock     = double('Google::Cloud::Storage file mock')

      allow(Google::Cloud::Storage).to receive(:new).and_return(storage_mock)
      allow(storage_mock).to receive(:bucket).and_return(bucket_mock)
      allow(bucket_mock).to receive(:file).and_return(file_mock)
      allow(file_mock).to receive(:download)

      gcs(
        '/path/to/gcs_keyfile',
        'test-project',
        'test-bucket',
        'download',
        '/path/to/source_file',
        '/path/to/dest_file'
      )

      expect(ENV.fetch('GOOGLE_CLOUD_KEYFILE')).to eq('/path/to/gcs_keyfile')

      expect(Google::Cloud::Storage).to have_received(:new).with(
        project: 'test-project',
        retries: 3,
        timeout: 3600
      ).once
      expect(storage_mock).to have_received(:bucket).with('test-bucket').once
      expect(bucket_mock).to have_received(:file).with('/path/to/source_file').once
      expect(file_mock).to have_received(:download).with('/path/to/dest_file').once
    end

    it "should delete file" do
      storage_mock  = double('Google::Cloud::Storage mock')
      bucket_mock   = double('Google::Cloud::Storage bucket mock')
      file_mock     = double('Google::Cloud::Storage file mock')

      allow(Google::Cloud::Storage).to receive(:new).and_return(storage_mock)
      allow(storage_mock).to receive(:bucket).and_return(bucket_mock)
      allow(bucket_mock).to receive(:file).and_return(file_mock)
      allow(file_mock).to receive(:delete)

      gcs(
        '/path/to/gcs_keyfile',
        'test-project',
        'test-bucket',
        'delete',
        '/path/to/source_file',
        '/path/to/dest_file'
      )

      expect(ENV.fetch('GOOGLE_CLOUD_KEYFILE')).to eq('/path/to/gcs_keyfile')

      expect(Google::Cloud::Storage).to have_received(:new).with(
        project: 'test-project',
        retries: 3,
        timeout: 3600
      ).once
      expect(storage_mock).to have_received(:bucket).with('test-bucket').once
      expect(bucket_mock).to have_received(:file).with('/path/to/source_file').once
      expect(file_mock).to have_received(:delete).once
    end
  end
end
