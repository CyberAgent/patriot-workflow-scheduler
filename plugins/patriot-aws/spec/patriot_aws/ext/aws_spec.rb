require 'init_test'
include PatriotAWS::Ext::AWS

describe PatriotAWS::Ext::AWS do
  describe 'config_aws' do
    it 'should update credentials' do
      options = {
        access_key_id: 'test_access_key_id',
        secret_access_key: 'test_secret_access_key'
      }

      expect(Aws.config).to receive(:update).once
      expect(Aws::Credentials).to receive(:new).once.with(
        options[:access_key_id],
        options[:secret_access_key]
      )

      config_aws(options)
    end

    it 'should update credentials and region' do
      options = {
        access_key_id: 'test_access_key_id',
        secret_access_key: 'test_secret_access_key',
        region: 'test_region'
      }

      options1 = {
        access_key_id: 'test_access_key_id',
        secret_access_key: 'test_secret_access_key'
      }
      options2 = { region: 'test_region' }

      expect(Aws::Credentials).to receive(:new).once.with(
        options1[:access_key_id],
        options1[:secret_access_key]
      )
      expect(Aws.config).to receive(:update).once.with({
        :credentials => anything
      })
      expect(Aws.config).to receive(:update).once.with(options2)

      config_aws(options)
    end
  end
end
