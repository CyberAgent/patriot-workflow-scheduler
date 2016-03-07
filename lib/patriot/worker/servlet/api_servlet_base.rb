require 'sinatra/base'

module Patriot
  module Worker
    module Servlet
      class APIServletBase < Sinatra::Base
        set :show_exceptions, :after_handler

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

        # @param worker [Patriot::Wokrer::Base]
        # @param config [Patriot::Util::Config::Base]
        def self.configure(worker, config)
          @@worker = worker
          @@config = config
          @@username  = config.get(Patriot::Util::Config::USERNAME_KEY, "")
          @@password  = config.get(Patriot::Util::Config::PASSWORD_KEY, "")
        end

      end
    end
  end
end
