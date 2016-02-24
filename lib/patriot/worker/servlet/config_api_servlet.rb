require 'sinatra/base'

module Patriot
  module Worker
    module Servlet

      # allow to monitor worker status
      class ConfigAPIServlet < Sinatra::Base

        VERSION_KEY = "version"
        CLASS_KEY = "class"
        STARTED_AT_KEY = "started_at"
        CONFIG_KEY = "config"

        # @param worker [Patriot::Worker::Base]
        # @param config [Patriot::Util::Config::Base]
        def self.configure(worker, config)
          @@worker = worker
          @@config = config
        end

        before do
          @worker = @@worker
        end

        get '/' do
          return JSON.generate(
            VERSION_KEY => Patriot::VERSION,
            CLASS_KEY => @@worker.class.to_s,
            STARTED_AT_KEY => @@worker.started_at,
            CONFIG_KEY => {} # TODO
          )
        end

      end
    end
  end
end
