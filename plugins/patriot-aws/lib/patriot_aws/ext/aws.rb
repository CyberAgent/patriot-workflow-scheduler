require 'aws-sdk'

module PatriotAWS
  module Ext
    module AWS
      def self.included(cls)
        cls.send(:include, Patriot::Util::System)
      end

      def config_aws(options)
        options.symbolize_keys
        Aws.config.update(
          access_key_id: options[:access_key_id],
          secret_access_key: options[:secret_access_key]
        )

        if options[:region]
          Aws.config.update(
            region: options[:region]
          )
        end
      end
    end
  end
end
