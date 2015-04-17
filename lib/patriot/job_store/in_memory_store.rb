require 'thread'

module Patriot
  module JobStore
    # a JobStore implementation on memory
    class InMemoryStore < Patriot::JobStore::Base
      include Patriot::Util::Logger
      include Patriot::Util::Retry

      # @see Patriot::JobStore::Base#initialize
      def initialize(store_id, config)
        @config = config
        @logger = create_logger(config)
        @mutex  = Mutex.new
        @jobs       = {} # hash from job_id to job content in hash
        # hash from state to list of job_id
        @job_states = {Patriot::JobStore::JobState::INIT      => [],
                       Patriot::JobStore::JobState::SUCCEEDED => [Patriot::JobStore::INITIATOR_JOB_ID],
                       Patriot::JobStore::JobState::WAIT      => [],
                       Patriot::JobStore::JobState::RUNNING   => [],
                       Patriot::JobStore::JobState::SUSPEND   => [],
                       Patriot::JobStore::JobState::FAILED    => []}
        @producers   = {} # hash from job_id to produces products
        @consumers   = {} # hash from job_id to referece products
        @job_history = {} # hash from job_id to a array of its execution hisotry
      end

      # @see Patriot::JobStore::Base#register
      def register(update_id, jobs)
        jobs.each{|job| raise "#{job.job_id} is not acceptable" unless acceptable?(job) }
        @mutex.synchronize do
          jobs.each do |job|
            job_id        = job.job_id.to_sym
            job.update_id = update_id
            if @jobs.has_key?(job_id) # update
              job[Patriot::Command::STATE_ATTR] ||= @jobs[job_id][Patriot::Command::STATE_ATTR]
            else # insert
              # set default state
              job[Patriot::Command::STATE_ATTR] ||= Patriot::JobStore::JobState::INIT
            end
            @jobs[job_id]      = job
            @producers[job_id] = job[Patriot::Command::PRODUCTS_ATTR] unless job[Patriot::Command::PRODUCTS_ATTR].nil?
            @consumers[job_id] = job[Patriot::Command::REQUISITES_ATTR] unless job[Patriot::Command::REQUISITES_ATTR].nil?
            if job[Patriot::Command::STATE_ATTR] == Patriot::JobStore::JobState::INIT
              _set_state(job_id, Patriot::JobStore::JobState::WAIT)
            else
              _set_state(job_id, job[Patriot::Command::STATE_ATTR])
            end
          end
        end
      end

      # @see Patriot::JobStore::Base#acceptable?
      def acceptable?(job)
        raise "invalid class #{job.class}" unless job.is_a?(Patriot::JobStore::Job)
        return true
      end

      # @see Patriot::JobStore::Base#get_job_tickets
      def get_job_tickets(host, nodes, options = {})
        nodes = [nodes] unless nodes.is_a?(Array)
        @mutex.synchronize do
          return @job_states[Patriot::JobStore::JobState::WAIT].map do |wid|
            job = @jobs[wid]
            # check host and node
            next unless job[Patriot::Command::EXEC_NODE_ATTR].nil?      || nodes.include?(job[Patriot::Command::EXEC_NODE_ATTR])
            next unless job[Patriot::Command::EXEC_HOST_ATTR].nil?      || host == job[Patriot::Command::EXEC_HOST_ATTR]
            next unless job[Patriot::Command::START_DATETIME_ATTR].nil? || Time.now > job[Patriot::Command::START_DATETIME_ATTR]
            # check dependency
            reference = @consumers[wid] || []
            producers = @producers.map{|pid, prods| pid unless (prods & reference).empty?}.compact
            next if !reference.empty? && producers.empty? # no producer exists
            next if producers.any?{|pjid| !@job_states[Patriot::JobStore::JobState::SUCCEEDED].include?(pjid)}
            JobTicket.new(wid.to_s, job.update_id, job[Patriot::Command::EXEC_NODE_ATTR])
          end.compact
        end
      end

      # @see Patriot::JobStore::Base#offer_to_execute
      def offer_to_execute(job_ticket)
        job_id    = job_ticket.job_id.to_sym
        update_id = job_ticket.update_id
        @mutex.synchronize do
          unless _check_and_set_state(job_id, update_id, Patriot::JobStore::JobState::WAIT, Patriot::JobStore::JobState::RUNNING)
            @logger.debug("execution of job: #{job_id} is skipped")
            return
          end
          job = @jobs[job_id]
          raise "no entry found for #{job_ticket}" if job.nil?
          begin
            # TODO make the max number of histories configurable and keep multiple histories
            execution_id         = Time.now.to_i
            @job_history[job_id] = [{:id       => execution_id,
                                     :job_id   => job_id.to_s,
                                     :host     => job_ticket.exec_host,
                                     :node     => job_ticket.exec_node,
                                     :thread   => job_ticket.exec_thread,
                                     :begin_at => Time.now
                                   }]
            return {:execution_id => execution_id, :command => job.to_command(@config)}
          rescue Exception => e
            _check_and_set_state(job_id, update_id, Patriot::JobStore::JobState::RUNNING, Patriot::JobStore::JobState::FAILED)
            raise e
          end
        end
      end

      # @see Patriot::JobStore::Base#report_completion_status
      def report_completion_status(job_ticket)
        job_id    = job_ticket.job_id.to_sym
        update_id = job_ticket.update_id
        exit_code = job_ticket.exit_code
        raise "exit code is not set " if exit_code.nil?
        state     = Patriot::JobStore::EXIT_CODE_TO_STATE[exit_code]
        raise "invalid exit code #{exit_code} " if state.nil?
        @mutex.synchronize do
          # TODO save finish_time to history server
          last_history = @job_history[job_id]
          raise "illegal state job_history is not set for #{job_id}" if last_history.nil? || last_history.empty?
          last_history = last_history[0]
          # TODO make the max number of histories configurable and keep multiple histories
          @job_history[job_id] = [last_history.merge({:state => exit_code, :end_at => Time.now, :description => job_ticket.description})]
          return _check_and_set_state(job_id, update_id, Patriot::JobStore::JobState::RUNNING, state)
        end
      end

      # @see Patriot::JobStore::Base#set_state
      def set_state(update_id, job_ids, new_state)
        @mutex.synchronize do
          job_ids = job_ids.map do |jid|
            @jobs[jid.to_sym][Patriot::Command::STATE_ATTR] = new_state
            jid.to_sym
          end
          @job_states.each do |s,jobs|
            next if s == new_state
            @job_states[s] -= job_ids
          end
          @job_states[new_state] += job_ids
        end
      end

      # @see Patriot::JobStore::Base#get_job
      def get_job(job_id)
        return @jobs[job_id.to_sym]
      end

      # @see Patriot::JobStore::Base#get_producers
      def get_producers(products, opts = {:include_attrs => [Patriot::Command::STATE_ATTR]})
        opts = {:include_attrs => []}.merge(opts)
        products = [products] unless products.is_a?(Array)
        producers = {}
        products.each{|product| 
          @producers.map{|pid, prods| 
            producers[pid.to_s] = @jobs[pid].filter_attributes(opts[:include_attrs]) if prods.include?(product)
          }
        }
        return producers
      end
  
      # @see Patriot::JobStore::Base#get_consumers
      def get_consumers(products, opts = {:include_attrs => [Patriot::Command::STATE_ATTR]})
        opts = {:include_attrs => []}.merge(opts)
        products = [products] unless products.is_a?(Array)
        consumers = {}
        products.each{|product|
          @consumers.map{|pid, prods| 
            consumers[pid.to_s] = @jobs[pid].filter_attributes(opts[:include_attrs]) if prods.include?(product)
          }
        }
        return consumers
      end

      # @see Patriot::JobStore::Base#find_jobs_by_state
      def find_jobs_by_state(state, opts = {})
        all_records = @job_states[state] - [Patriot::JobStore::INITIATOR_JOB_ID]
        size        = all_records.size
        opts        = {:limit => size, :offset => 0}.merge(opts)
        filter      = opts.has_key?(:filter_exp) ? Regexp.new(opts[:filter_exp].gsub(/(?<!\\)%/,'.*').gsub(/(?<!\\)_/,'.')) : nil
        result      = []
        opts[:offset].upto(size).each do |i|
          break if i >= size
          break if result.size >= opts[:limit]
          job_id = all_records[size - 1 - i].to_s
          next  if !filter.nil? && !filter.match(job_id)
          result << job_id
        end
        return result
      end

      # @see Patriot::JobStore::Base#get_execution_history
      def get_execution_history(job_id, opts = {})
        opts = {:limit => 1, :order => :DESC}
        return @job_history[job_id.to_sym] || []
      end

      # @see Patriot::JobStore::Base#get_job_size
      def get_job_size(opts = {})
        opts  = {:ignore_states => []}.merge(opts)
        sizes = {}
        @job_states.each do |s,js|
          next if opts[:ignore_states].include?(s)
          sizes[s] = js.size
          sizes[s] = sizes[s] -1 if s == Patriot::JobStore::JobState::SUCCEEDED
        end
        return sizes
      end

      # @see Patriot::JobStore::Base#delete_job
      def delete_job(job_id)
        job_id = job_id.to_sym
        @mutex.synchronize do 
          @job_states.each{|s,js| js.delete(job_id)}
          @jobs.delete(job_id)
          @producers.delete(job_id)
          @consumers.delete(job_id)
        end
      end

      ### private

      # not thread safe. should be locked around invocation
      # @param [Symbol] job_id
      # @param [Integer] update_id
      # @param [Integer] prev_state
      # @param [Integer] post_state
      # @return [Boolean] true if state is changed, otherwise false
      def _check_and_set_state(job_id, update_id, prev_state, post_state)
        return false unless @job_states[prev_state].include?(job_id)
        return false unless @jobs[job_id].update_id == update_id
        _set_state(job_id, post_state)
        return true
      end
      private :_check_and_set_state

      # set job state
      # @param [String] job_id
      # @param [Integer] new_state new state of the job. set nil to keep_state
      def _set_state(job_id, new_state)
        return if new_state.nil?
        job_id = job_id.to_sym
        @job_states.each do |s,jobs|
          deleted_id = jobs.delete(job_id)
          break unless deleted_id.nil?
        end
        @jobs[job_id][Patriot::Command::STATE_ATTR] = new_state
        @job_states[new_state] << job_id
      end
      private :_set_state

    end
  end
end
