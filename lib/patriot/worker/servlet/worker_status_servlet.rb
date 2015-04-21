require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet

      # allow to monitor worker status
      class WorkerStatusServlet < Sinatra::Base
        register Sinatra::Contrib

        set :public_folder, File.join($home, "public")
        set :views, File.join($home, "public", "templates")

        # @param worker [Patriot::Worker::Base]
        # @param config [Patriot::Util::Config::Base]
        def self.configure(worker, config)
          @@worker = worker
        end

        before do
          @worker = @@worker
        end

        get '/' do
          respond_with :worker, {:worker => @worker} do |f|
            # for monitoring
            f.on('*/*') { JSON.generate(@worker.host => @worker.status)}
          end
        end

        put '/' do
          new_status = params['status']
          if [Patriot::Worker::Status::ACTIVE, Patriot::Worker::Status::SLEEP ]
            @worker.status = new_status
          else
            return 400
          end
        end

      end
    end
  end
end
