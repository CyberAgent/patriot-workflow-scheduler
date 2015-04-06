require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet
      DEFAULT_JOB_LIMIT = 50
      DEFAULT_JOB_OFFSET = 0

      USERNAME_KEY = 'info_server.admin.username'
      PASSWORD_KEY = 'info_server.admin.password'

      require 'patriot/worker/servlet/job_servlet.rb'
      require 'patriot/worker/servlet/worker_status_servlet.rb'

    end
  end
end
