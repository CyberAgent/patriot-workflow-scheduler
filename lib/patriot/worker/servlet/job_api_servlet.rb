require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet
      # excepton thrown in case job not found
      class JobNotFoundException < Exception; end
      # provide job management functionalities
      class JobAPIServlet < Sinatra::Base
        register Sinatra::Contrib
        include Patriot::Util::DateUtil
        include Patriot::Command::Parser

        set :show_exceptions, :after_handler

        # @param worker [Patriot::Wokrer::Base]
        # @param config [Patriot::Util::Config::Base]
        def self.configure(worker, config)
          @@job_store = worker.job_store
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

        get '/stats' do
          return JSON.generate(@@job_store.get_job_size(:ignore_states => [Patriot::JobStore::JobState::SUCCEEDED]))
        end

        get '/' do
          state  = (params['state']  || Patriot::JobStore::JobState::FAILED).to_i
          limit  = (params['limit']  || DEFAULT_JOB_LIMIT).to_i
          offset = (params['offset'] || DEFAULT_JOB_OFFSET).to_i

          query = {:limit  => limit, :offset => offset}
          query[:filter_exp] = params['filter_exp'] unless params['filter_exp'].blank?
          job_ids = @@job_store.find_jobs_by_state(state, query) || []
          return JSON.generate(job_ids.map{|job_id| {:job_id => job_id, :state => state}})
        end

        get '/:job_id' do
          job_id = params[:job_id]
          job = @@job_store.get(job_id, {:include_dependency => true})
          halt(404, json({ERROR: "Job #{job_id} not found"})) if job.nil?
          return JSON.generate(job.attributes.merge({'job_id' => job_id, "update_id" => job.update_id}))
        end

        get '/:job_id/histories' do
          job_id = params[:job_id]
          history_size = params['size'] || 3
          histories = @@job_store.get_execution_history(job_id, {:limit => history_size})
          return JSON.generate(histories)
        end

        post '/' do
          protected!
          body = JSON.parse(request.body.read)
          halt(400, json({ERROR: "COMMAND_CLASS is not provided"})) if body["COMMAND_CLASS"].blank?
          halt(400, json({ERROR: "Patriot::Command::CommandGroup is not acceptable"})) if body["COMMAND_CLASS"] == "Patriot::Command::CommandGroup"
          command_class = body.delete("COMMAND_CLASS").gsub(/\./, '::').constantize

          job = _build_command(command_class, body)[0]
          job[Patriot::Command::STATE_ATTR] ||= body["state"]
          @@job_store.register(Time.now.to_i, [job])
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
          job = @@job_store.get(job_id)
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
          job_ids.each{ |job_id| @@job_store.delete_job(job_id) }
          return JSON.generate(job_ids.map{|job_id| {"job_id" => job_id} })
        end

        delete '/:job_id' do
          protected!
          job_id = params['job_id']
          job = @@job_store.get(job_id)
          halt(404, json({ERROR: "Job #{job_id} not found"})) if job.nil?

          @@job_store.delete_job(job_id)
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
          @@job_store.set_state(update_id, job_ids, state)
          if opts['with_subsequent']
            @@job_store.process_subsequent(job_ids) do |job_store, jobs|
              next if jobs.empty?
              subsequent_ids = jobs.map(&:job_id)
              @@job_store.set_state(update_id, subsequent_ids, state)
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
