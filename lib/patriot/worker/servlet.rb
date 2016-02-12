require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    # namespacce infoserve servlet
    module Servlet
      # default limit in searching jobs
      DEFAULT_JOB_LIMIT = 50
      # default offset for searching jobs
      DEFAULT_JOB_OFFSET = 0

      # configuratio key for admin user name
      USERNAME_KEY = 'info_server.admin.username'
      # configuratio key for admin password
      PASSWORD_KEY = 'info_server.admin.password'

      require 'patriot/worker/servlet/job_servlet.rb'
      require 'patriot/worker/servlet/job_api_servlet.rb'
      require 'patriot/worker/servlet/worker_status_servlet.rb'

    end
  end
end
