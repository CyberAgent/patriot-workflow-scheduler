require 'thin'
require 'rack/rewrite'

module Patriot
  module Worker
    # info server (web management console and for monitoring)
    class InfoServer

      # configuratio key for port used by this server
      PORT_KEY = 'info_server.port'
      # default port number
      DEFAULT_PORT = '36104'

      # configuration key for rack handler used to start this server
      RACK_HANDLER_KEY   = 'info_server.rack.handler'
      # default rack handler
      # DEFAULT_RACK_HANDLER = 'Rack::Handler::WEBrick'
      DEFAULT_RACK_HANDLER = 'Rack::Handler::Thin'

      include Patriot::Util::Config
      include Patriot::Util::Logger

      attr_accessor :port

      # @param worker [Patriot::Worker::Base] worker managed through this server
      # @param config [Patriot::Util::Config::Bae]
      def initialize(worker, config)
        @logger = create_logger(config)
        @worker = worker
        @config = config
        @port = @config.get(Patriot::Worker::InfoServer::PORT_KEY,
                            Patriot::Worker::InfoServer::DEFAULT_PORT)
      end

      # start the server
      def start_server
        if @port.nil?
          @logger.info("port is not set. starting info server is skipped")
          return
        end
        @server_thread = Thread.new do
          begin
            @handler = eval(@config.get(RACK_HANDLER_KEY, DEFAULT_RACK_HANDLER))
            app = Rack::URLMap.new(get_url_map)
            app = Rack::CommonLogger.new(app, build_access_logger)
            app = Rack::Rewrite.new(app){
              # below 4 rules are for backward compatibility
              r301 %r{^/jobs/?$}, "/"
              rewrite %r{^/jobs/([^/]+)$}, "/api/v1/jobs/$1"
              rewrite "/worker", "/api/v1/workers/this/state"
              rewrite "/worker/status", "/api/v1/workers/this/state"
              # for web console
              rewrite %r{^(?!/api)}, "/"
            }
            app = Rack::Static.new(app, :urls => ["/js", "/css"], :root => File.join($home, "public"))
            # TODO set options based on Handler type
            @handler.run(app, {:Port => @port, :Host => '0.0.0.0', :signals => false}) do |server|
              server.threaded = true
              server.threadpool_size = 5
              server.timeout = 60
            end
          rescue => e
            @logger.error e
            raise e
          end
        end
        @logger.info "info server has started with #{@handler.class}"
        return true
      end

      # @return [Hash<String, Sinatra::Base>]
      def get_url_map
        urlmap = {"/" => Patriot::Worker::Servlet::IndexServlet,
                  "/api/v1/jobs" => Patriot::Worker::Servlet::JobAPIServlet,
                  "/api/v1/workers" => Patriot::Worker::Servlet::WorkerAPIServlet}
        urlmap.values.each{|servlet| servlet.configure(@worker, @config)}
        return urlmap
      end

      def build_access_logger
        config = load_config(:path => @config.path, :type => 'web', :ignore_plugin => true)
        return Patriot::Util::Logger::Factory.create_logger(@hanlder.class.to_s, config)
      end
      private :build_access_logger

      # instruct to shutdown server
      def shutdown_server
        return false if @server.nil?
        unless @server_thread.nil?
          begin
            @handler.shutdown
            @logger.info "info server shutdowned"
          rescue => e
            @logger.error "failed to shutdown infoserver", e
            raise e
          end
        end
      end

    end
  end
end
