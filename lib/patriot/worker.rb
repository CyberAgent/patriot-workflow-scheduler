module Patriot
  module Worker
    # states of worker
    module Status
      ACTIVE   = 'ACTIVE'
      SLEEP    = 'SLEEP'
      SHUTDOWN = 'SHUTDOWN'
    end

    # name of thread local variable for job_id executed by the thread
    JOB_ID_IN_EXECUTION          = :JOB_ID_IN_EXECUTION

    # SIGNAL used for graceful shutdown
    SIGNAL_FOR_GRACEFUL_SHUTDOWN = ['INT', 'TERM']
    # SIGNAL used for getting thread dump
    SIGNAL_FOR_THREAD_DUMP       = ['QUIT']

    DEFAULT_FETCH_CYCLE = 300
    DEFAULT_FETCH_LIMIT = 200
    DEFAULT_WORKER_NAME = 'default'

    require 'patriot/worker/servlet'
    require 'patriot/worker/info_server'
    require 'patriot/worker/base'
    autoload :MultiNodeWorker, 'patriot/worker/multi_node_worker'
    autoload :JobStoreServer, 'patriot/worker/job_store_server'
  end
end
