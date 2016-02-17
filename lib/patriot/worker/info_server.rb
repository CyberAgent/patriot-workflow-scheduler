module Patriot
  module Worker
    # info server (web management console and for monitoring)
    class InfoServer

      # configuratio key for port used by this server
      PORT_KEY = 'info_server.port'
      # default port number
      DEFAULT_PORT = '36104'

      # urls used by this server
      URLS_KEY           = 'info_server.urls'
      # mapping from the url to a servlet for the url
      URL_MAP_KEY_PREFIX = 'info_server.urlmap'

      # configuration key for rack handler used to start this server
      RACK_HANDLER_KEY   = 'info_server.rack.handler'
      # default rack handler
      DEFAULT_RACK_HANDLER = 'Rack::Handler::WEBrick'

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
            @handler.run app, {:Port => @port, :Host => '0.0.0.0'}
          rescue => e
            @logger.error e
          end
        end
        @logger.info "info server has started"
        return true
      end

      # @return [Hash<String, Sinatra::Base>]
      def get_url_map
        urls = @config.get(URLS_KEY, nil)
        if urls.nil?
          urlmap = {"/jobs"   => Patriot::Worker::Servlet::JobServlet,
                    "/api/v1/jobs" => Patriot::Worker::Servlet::JobAPIServlet,
                    "/worker" => Patriot::Worker::Servlet::WorkerStatusServlet}
        else
          urlmap = {}
          urls = [url] unless urls.is_a? Array
          urls.each do |u|
            servlet = eval( @config.get("#{URL_MAP_KEY_PREFIX}.#{u}") )
            u = "/#{u}" unless u.start_with?("/")
            urlmap[u] = servlet
          end
        end
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
          @handler.shutdown
          @logger.info "info server shutdowned"
        end
      end

    end
  end
end
