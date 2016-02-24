require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet

      # allow to monitor worker status
      class IndexServlet < Sinatra::Base
        register Sinatra::Contrib

        set :public_folder, File.join($home, "public")
        set :views, File.join($home, "public", "views")

        # @param worker [Patriot::Worker::Base]
        # @param config [Patriot::Util::Config::Base]
        def self.configure(worker, config)
          @@worker = worker
        end

        before do
          @worker = @@worker
        end

        get '/' do
          erb :index
        end

      end
    end
  end
end
