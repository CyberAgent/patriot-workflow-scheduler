require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet
      # excepton thrown in case job not found
      class JobNotFoundException < Exception; end
      # provide job management functionalities
      class JobAPIServlet < Patriot::Worker::Servlet::APIServletBase
        register Sinatra::Contrib
        include Patriot::Util::DateUtil
        include Patriot::Command::Parser

        set :show_exceptions, :after_handler

        get '/stats' do
          return JSON.generate(@@worker.job_store.get_job_size(:ignore_states => [Patriot::JobStore::JobState::SUCCEEDED]))
        end

        get '/' do
          state  = (params['state']  || Patriot::JobStore::JobState::FAILED).to_i
          limit  = (params['limit']  || DEFAULT_JOB_LIMIT).to_i
          offset = (params['offset'] || DEFAULT_JOB_OFFSET).to_i

          query = {:limit  => limit, :offset => offset}
          query[:filter_exp] = params['filter_exp'] unless params['filter_exp'].nil? || params['filter_exp'].empty?
          job_ids = @@worker.job_store.find_jobs_by_state(state, query) || []
          return JSON.generate(job_ids.map{|job_id| {:job_id => job_id, :state => state}})
        end

        get '/:job_id' do
          job_id = params[:job_id]
          job = @@worker.job_store.get(job_id, {:include_dependency => true})
          halt(404, json({ERROR: "Job #{job_id} not found"})) if job.nil?
          return JSON.generate(job.attributes.merge({'job_id' => job_id, "update_id" => job.update_id}))
        end

        get '/:job_id/histories' do
          job_id = params[:job_id]
          history_size = params['size'] || 3
          histories = @@worker.job_store.get_execution_history(job_id, {:limit => history_size})
          return JSON.generate(histories)
        end

        # get dependency graph of the specified job
        #
        # @param [String] job_id
        # @param [String] p_level a max number of producer dependency level to get
        # @param [String] c_level a max number of consumer dependency level to get
        get '/:job_id/graph' do
          job_id = params[:job_id]
          producer_depth = (params['p_depth'] || 2).to_i
          consumer_depth = (params['c_depth'] || 2).to_i
          graph = @@worker.job_store.get_graph(job_id, {:producer_depth => producer_depth, :consumer_depth => consumer_depth})
          return JSON.generate(graph)
        end

        post '/' do
          protected!
          body = JSON.parse(request.body.read)
          halt(400, json({ERROR: "COMMAND_CLASS is not provided"})) if body["COMMAND_CLASS"].empty?
          halt(400, json({ERROR: "Patriot::Command::CommandGroup is not acceptable"})) if body["COMMAND_CLASS"] == "Patriot::Command::CommandGroup"
          command_class = body.delete("COMMAND_CLASS").gsub(/\./, '::').constantize

          job = _build_command(command_class, body)[0]
          job[Patriot::Command::STATE_ATTR] ||= body["state"]
          job[Patriot::Command::START_DATETIME_ATTR] = Time.parse body["start_datetime"] if body["start_datetime"]
          @@worker.job_store.register(Time.now.to_i, [job])
          return JSON.generate({:job_id => job.job_id})
        end

        put '/' do
          protected!
          body = JSON.parse(request.body.read)
          job_ids = body["job_ids"]
          state = body['state']
          _set_state_of_jobs(job_ids, state)
          return JSON.generate(job_ids.map{|job_id| {"job_id" => job_id, "state" => state} })
        end

        put '/:job_id' do
          protected!
          job_id = params['job_id']
          job = @@worker.job_store.get(job_id)
          halt(404, json({ERROR: "Job #{job_id} not found"})) if job.nil?

          body = JSON.parse(request.body.read)
          state = body['state']
          options = body['option'] || {}
          job_ids = _set_state_of_jobs(job_id, state, options)
          return JSON.generate(job_ids.map{|jid| {"job_id" => jid, "state" => state}})
        end

        delete '/' do
          protected!
          body = request.body.read
          job_ids = []
          if body != ''
            body = JSON.parse(body)
            job_ids = body["job_ids"]
          else
            job_ids = JSON.parse(params["job_ids"])
          end
          job_ids.each{ |job_id| @@worker.job_store.delete_job(job_id) }
          return JSON.generate(job_ids.map{|job_id| {"job_id" => job_id} })
        end

        delete '/:job_id' do
          protected!
          job_id = params['job_id']
          job = @@worker.job_store.get(job_id)
          halt(404, json({ERROR: "Job #{job_id} not found"})) if job.nil?

          @@worker.job_store.delete_job(job_id)
          return JSON.generate({"job_id" => job_id})
        end

        error JobNotFoundException do
          "Job #{env['sinatra.error'].message} is not found"
        end

        # @private
        def _set_state_of_jobs(job_ids, state, opts = {})
          job_ids = [job_ids] unless job_ids.is_a? Array
          opts = {'with_subsequent' => false}.merge(opts)
          opts = {:include_subsequent => false}.merge(opts)
          update_id = Time.now.to_i
          @@worker.job_store.set_state(update_id, job_ids, state)
          if opts['with_subsequent']
            @@worker.job_store.process_subsequent(job_ids) do |job_store, jobs|
              next if jobs.empty?
              subsequent_ids = jobs.map(&:job_id)
              @@worker.job_store.set_state(update_id, subsequent_ids, state)
              job_ids |= subsequent_ids
            end
          end
          return job_ids.uniq
        end
        private :_set_state_of_jobs

        # @private
        def _build_command(clazz, params)
          _params = params.dup
          _params["target_datetime"] = Date.today
          cmd = clazz.new(@@config)
          cmd.produce(_params.delete("products")) unless _params["products"].nil?
          cmd.require(_params.delete("requisites")) unless _params["requisites"].nil?
          cmds = cmd.build(_params)
          return cmds.map{|c| c.to_job}
        end
        private :_build_command

      end
    end
  end
end
