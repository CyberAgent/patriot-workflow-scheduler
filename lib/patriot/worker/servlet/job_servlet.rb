require 'sinatra/base'
require 'sinatra/contrib'

module Patriot
  module Worker
    module Servlet
      class JobNotFoundException < Exception; end
      class JobServlet < Sinatra::Base
        register Sinatra::Contrib

        set :public_folder, File.join($home, "public")
        set :views, File.join($home, "public", "templates")
        set :show_exceptions, :after_handler

        def self.configure(worker, config)
          @@job_store = worker.job_store
          @@username  = config.get(USERNAME_KEY, "")
          @@password  = config.get(PASSWORD_KEY, "")
        end

        ### Helper Methods
        helpers do
          def to_job_link(job_id)
            return "<a href='/jobs/#{ERB::Util.url_encode(job_id)}'>#{job_id}</a>"
          end
          def protected!
            return if authorized?
            headers['WWW-Authenticate'] = 'Basic Realm="Admin Only"'
            halt 401, "Not Authorized"
          end
          def authorized?
            @auth ||= Rack::Auth::Basic::Request.new(request.env)
            return @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [@@username, @@password]
          end
        end

        get '/' do
          state = params['state'] || Patriot::JobStore::JobState::FAILED
          update_job_size(state)
          query = {:limit  => params['limit']  || DEFAULT_JOB_LIMIT,
                   :offset => params['offset'] || DEFAULT_JOB_OFFSET}
          query[:filter_exp] = params['filter_exp'] if params.has_key?('filter_exp') && params['filter_exp'] != ""
          jobs = @@job_store.find_jobs_by_state(state.to_i, query)
          jobs ||= []
          respond_with :jobs, {:jobs => jobs, :state => state, :filter_exp => query[:filter_exp]}.merge(query)
        end

        post '/' do
          protected!
          job_ids   = params['job_ids']
          if params['_method'] == 'put'
            state = params['state']
            set_state_of_jobs(job_ids, state)
          elsif params['_method'] == 'delete'
            delete_jobs(job_ids)
          else
            raise NotImplementedError
          end
        end

        get '/:job_id' do
          job_id = params[:job_id]
          history_size = params['history_size'] || 1
          job = @@job_store.get(job_id, {:include_dependency => true})
          raise JobNotFoundException, job_id if job.nil?
          update_job_size(job[Patriot::Command::STATE_ATTR])
          histories = @@job_store.get_execution_history(job_id, {:limit => history_size})
          # respond_with :job, {:job => job, :histories => histories} 
          respond_to do |f|
            f.on('text/html'){ erb :job, :locals => {:job => job, :histories => histories} }
            # for monitoring
            f.on('*/*'){ JSON.generate(job.attributes.merge({'job_id' => job_id})) }
          end
        end

        post '/:job_id' do
          protected!
          if params['_method'] == 'put'
            set_state_of_jobs([params['job_id']], params['state'], {:include_subsequent => params['include_subsequent'] == 'true'})
            respond_with :state_updated, {:jobs => job_ids, :state => state}
          else
            raise NotImplementedError
          end
        end

        error JobNotFoundException do
          "Job #{env['sinatra.error'].message} is not found"
        end

        def update_job_size(state)
          @size = @@job_store.get_job_size(:ignore_states => [Patriot::JobStore::JobState::SUCCEEDED])
        end

        def set_state_of_jobs(job_ids, state, opts = {})
          opts = {:include_subsequent => false}.merge(opts)
          update_id = Time.now.to_i
          if opts[:include_subsequent]
            dep_ids = job_ids.map{|did| get_subsequent(did)}.flatten
            job_ids |= dep_ids
          end
          @@job_store.set_state(update_id, job_ids, state)
          update_job_size(state)
          respond_with :state_updated, {:jobs => job_ids, :state => state}
        end
        private :set_state_of_jobs

        def delete_jobs(job_ids)
          job_ids.each{|jid| @@job_store.delete_job(jid) }
          update_job_size(Patriot::JobStore::JobState::DISCARDED)
          respond_with :jobs_deleted, {:jobs => job_ids}
        end
        private :delete_jobs

        def get_subsequent(job_id)
          job     = @@job_store.get(job_id, :include_dependency => true)
          dep_ids = job['consumers'].keys
          dep_ids |= dep_ids.map{|did| get_subsequent(did)}
          return dep_ids.flatten.compact.uniq
        end
        private :get_subsequent

      end
    end
  end
end