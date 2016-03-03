require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet
      # excepton thrown when a woker is not accessible
      class WorkerInaccessibleException < Exception; end
      # provide worker management functionalities
      class WorkerAPIServlet < Sinatra::Base
        register Sinatra::Contrib

        HOST_KEY = "host"
        VERSION_KEY = "version"
        CLASS_KEY = "class"
        STARTED_AT_KEY = "started_at"
        CONFIG_KEY = "config"

        STATE_KEY = "state"

        LOCALHOST_EXPS = ["localhost", "127.0.0.1"]

        set :show_exceptions, :after_handler

        # @param worker [Patriot::Wokrer::Base]
        # @param config [Patriot::Util::Config::Base]
        def self.configure(worker, config)
          @@worker = worker
          @@config = config
          @@username  = config.get(USERNAME_KEY, "")
          @@password  = config.get(PASSWORD_KEY, "")
        end

        ### Helper Methods
        helpers do
          # require authorization for updating
          def protected!
            return if authorized?
            headers['WWW-Authenticate'] = 'Basic Realm="Admin Only"'
            halt 401, "Not Authorized"
          end

          # authorize user (basic authentication)
          def authorized?
            @auth ||= Rack::Auth::Basic::Request.new(request.env)
            return @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [@@username, @@password]
          end
        end

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
            HOST_KEY => @@worker.host,
            VERSION_KEY => Patriot::VERSION,
            CLASS_KEY => @@worker.class.to_s,
            STARTED_AT_KEY => @@worker.started_at,
            CONFIG_KEY => {} # TODO
          )
        end

        get '/this/state' do
          return JSON.generate(
            'state' => @@worker.status
          )
        end

        put '/this/state' do
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
