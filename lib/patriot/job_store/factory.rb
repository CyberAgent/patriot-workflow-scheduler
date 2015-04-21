module Patriot
  module JobStore
    # a moulde for a factory method of JobStores
    module Factory
      # create JobStore for given store_id based on the configuration
      # @param store_id [String] JobStore ID to identify configuration parameters
      # @param config [Patriot::Util::Config::Base] configuration to create a JobStore
      # @return [Patriot::JobStore::Base]
      def create_jobstore(store_id, config)
        cls = config.get([Patriot::JobStore::CONFIG_PREFIX, store_id, "class"].join("."))
        # TODO set default store
        raise "class for job store #{store_id} is not specified" if cls.nil?
        job_store = eval(cls).new(store_id, config)
        return job_store
      end
      module_function :create_jobstore
    end
  end
end
