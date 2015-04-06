require 'rest_client'

module Patriot
  module Controller
    # Controller class for remote management of workers
    class WorkerAdminController
      include Patriot::Util::Config
      include Patriot::Util::Logger

      WORKER_COMMAND = File.join($home || Dir.pwd,'bin', 'patriot worker')
      UPGRADE_COMMAND = File.join($home || Dir.pwd,'bin', 'patriot upgrade')

      # constructor
      # @param config [Patriot::Util::Config::Base] configuration of this controller
      def initialize(config)
        @config = config
        @logger = create_logger(config)
        set_default_values
      end

      # @private
      def set_default_values
        @default_hosts = @config.get('worker_hosts') || []
        @default_port  = @config.get('info_server_port')
        @user          = @config.get('admin_user')
      end
      private :set_default_values

      # execute block for each target hosts
      # @param options [Hash]
      # @option options :host  a target host
      # @option options :hosts a comman separated value of target hosts
      # @option options :all   set true to target all hosts in the configuration 
      # @return [Hash] a hash from host name to the result of the block
      def request_to_target_hosts(options = {}, &blk)
        hosts = []
        port = options.has_key?(:port) ? options[:port] : @default_port
        if options.has_key?(:host)
          hosts = [options[:host]]
        elsif options.has_key?(:hosts)
          hosts = options[:hosts]
          hosts = hosts.split(",") unless hosts.is_a?(Array)
        elsif options[:all] == true
          hosts = @default_hosts
          hosts = [hosts] unless hosts.is_a?(Array)
        else
          raise "any host is not set"
        end
        results = {}
        hosts.each{|h| results[h] = yield(h,port) }
        return results
      end

      # get status of a worker or workers
      # @param options @see {#request_to_target_hosts}
      # @return [Hash]
      #   status of worker in String.
      #   nil for an unresponsive worker
      def status(options = {})
        return request_to_target_hosts(options){|h,p| get_worker_status(h,p)}
      end

      # get status of a worker
      # @param host [String] host name of the target host
      # @param port [String] port number of the worker process on the target host
      # @return [String] status of the server @see {Patriot::Worker::Base}
      def get_worker_status(host, port)
        begin
          return RestClient.get("http://#{host}:#{port}/worker")
        rescue Errno::ECONNREFUSED, SocketError
          return nil
        end
      end

      # sleep target workers
      # @param options @see {#request_to_target_hosts}
      def sleep_worker(options = {})
        return request_to_target_hosts(options){|h,p| put_worker_status(h,p,Patriot::Worker::Status::SLEEP)}
      end

      # wake up target workers
      # @param options @see {#request_to_target_hosts}
      def wake_worker(options = {})
        return request_to_target_hosts(options){|h,p| put_worker_status(h,p,Patriot::Worker::Status::ACTIVE)}
      end

      # change state of a worker
      # @param host [String] host name of the target host
      # @param port [String] port number of the worker process on the target host
      def put_worker_status(host, port, new_status)
        return RestClient.put("http://#{host}:#{port}/worker", :status => new_status)
      end

      # start target workers
      # @param options @see {#request_to_target_hosts}
      def start_worker(options = {})
        return request_to_target_hosts(options){|h,p| controll_worker_at(h,'start')}
      end

      # stop target workers
      # @param options @see {#request_to_target_hosts}
      def stop_worker(options = {})
        return request_to_target_hosts(options){|h,p| controll_worker_at(h,'stop')}
      end

      # restart target workers
      # @param options @see {#request_to_target_hosts}
      def restart_worker(options = {})
        options = {:interval => 60}.merge(options)
        target_nodes = request_to_target_hosts(options){|h,p| controll_worker_at(h,'stop')} 
        target_nodes.keys.each{|host| target_nodes[host] = true}

        port = options.has_key?(:port) ? options[:port] : @default_port
        while(target_nodes.has_value?(true))
          target_nodes.keys.each do |host|
            next unless target_nodes[host] # skip already started 
            res = get_worker_status(host,port)
            if res.nil?
              controll_worker_at(host,'start')
              target_nodes[host] = false
            else
              if res.code == 200
                @logger.info "status code from #{host} : #{res.code}"
              else
                @logger.warn "status code from #{host} : #{res.code}"
              end
            end
          end
          sleep options[:interval] if target_nodes.has_value?(true)
        end
      end

      # execute a worker command at a remote host
      # @param host [String] host name of the target host
      def controll_worker_at(host, cmd)
        ssh_cmd = "ssh -l #{@user} #{host} sudo #{WORKER_COMMAND} #{cmd}"
        @logger.info ssh_cmd
        puts `#{ssh_cmd}`
      end

      # upgrade libraries for target workers
      # @param options @see {#request_to_target_hosts}
      def upgrade_worker(options = {})
        return request_to_target_hosts(options){|h,p| do_upgrade_at(h)}
      end

      # execute upgrade commands at a remote host
      # @param host [String] host name of the target host
      def do_upgrade_at(host)
        ssh_cmd = "ssh -l #{@user} #{host} sudo #{UPGRADE_COMMAND}"
        @logger.info ssh_cmd
        puts `#{ssh_cmd}`
      end

    end
  end
end
