require 'init_test'
include PatriotAWS::Ext::AWS

describe PatriotAWS::Ext::AWS do
  describe 'config' do
    it 'should update credentials' do
      options = {
        access_key_id: 'test_access_key_id',
        secret_access_key: 'test_secret_access_key'
      }

      expect(Aws.config).to receive(:update)
        .once.with(options.symbolize_keys)

      PatriotAWS::Ext::AWS.config(options)
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

      expect(Aws.config).to receive(:update).once.with(options1)
      expect(Aws.config).to receive(:update).once.with(options2)

      PatriotAWS::Ext::AWS.config(options)
    end
  end
end
