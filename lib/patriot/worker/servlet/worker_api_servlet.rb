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

        set :show_exceptions, :after_handler

        # @param worker [Patriot::Wokrer::Base]
        # @param config [Patriot::Util::Config::Base]
        def self.configure(worker, config)
          @@wokrer = worker
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
          worker_hosts = @@config.get(Patriot::Util::Config::WORKER_HOST_KEY)
          return JSON.generate(worker_hosts)
        end

      end
    end
  end
end
