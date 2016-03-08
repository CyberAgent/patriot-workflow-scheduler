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

      require 'patriot/worker/servlet/index_servlet.rb'
      require 'patriot/worker/servlet/api_servlet_base.rb'
      require 'patriot/worker/servlet/job_api_servlet.rb'
      require 'patriot/worker/servlet/worker_api_servlet.rb'
    end
  end
end
