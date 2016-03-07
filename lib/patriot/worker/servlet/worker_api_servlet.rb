require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet
      # excepton thrown when a woker is not accessible
      class WorkerInaccessibleException < Exception; end
      # provide worker management functionalities
      class WorkerAPIServlet < Patriot::Worker::Servlet::APIServletBase
        register Sinatra::Contrib

        HOST_KEY = "host"
        VERSION_KEY = "version"
        CLASS_KEY = "class"
        STARTED_AT_KEY = "started_at"
        CONFIG_KEY = "config"

        STATE_KEY = "state"

        LOCALHOST_EXPS = ["localhost", "127.0.0.1"]

        set :show_exceptions, :after_handler

        get '/' do
          worker_hosts = @@config.get(Patriot::Util::Config::WORKER_HOST_KEY).map do |h|
            h = h.split(":")
            port = h.size == 2 ? h[1] : Patriot::Worker::InfoServer::DEFAULT_PORT
            {'host' => h[0], 'port' => port}
          end
          return JSON.generate(worker_hosts)
        end

        get '/this' do
          return JSON.generate(
            STATE_KEY => @@worker.status,
            HOST_KEY => @@worker.host,
            VERSION_KEY => Patriot::VERSION,
            CLASS_KEY => @@worker.class.to_s,
            STARTED_AT_KEY => @@worker.started_at,
            CONFIG_KEY => {} # TODO
          )
        end

        get '/this/state' do
          return JSON.generate(
            STATE_KEY => @@worker.status
          )
        end

        put '/this/state' do
          protected!
          new_status = params['status']
          if [Patriot::Worker::Status::ACTIVE, Patriot::Worker::Status::SLEEP ]
            @@worker.status = new_status
          else
            # state cannot be changed in shotdown process
            halt 403
          end
        end

      end
    end
  end
end
