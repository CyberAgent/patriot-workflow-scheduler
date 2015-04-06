module Patriot
  module Worker
    class InfoServer

      PORT_KEY = 'info_server.port'
      DEFAULT_PORT = '36104'

      URLS_KEY           = 'info_server.urls'
      URL_MAP_KEY_PREFIX = 'info_server.urlmap'

      RACK_HANDLER_KEY   = 'info_server.rack.handler'
      DEFAULT_RACK_HANDLER = 'Rack::Handler::WEBrick'

      include Patriot::Util::Config
      include Patriot::Util::Logger

      def initialize(worker, config)
        @logger = create_logger(config)
        @worker = worker
        @config = config
      end

      def start_server
        port = @config.get(Patriot::Worker::InfoServer::PORT_KEY,
                           Patriot::Worker::InfoServer::DEFAULT_PORT)
        if port.nil?
          @logger.info("port is not set. starting info server is skipped")
          return
        end
        @server_thread = Thread.new do 
          begin
            @handler = eval(@config.get(RACK_HANDLER_KEY, DEFAULT_RACK_HANDLER))
            app = Rack::URLMap.new(get_url_map)
            app = Rack::CommonLogger.new(app, build_access_logger)
            @handler.run app, {:Port => port, :Host => '0.0.0.0'}
          rescue => e
            @logger.error e
          end
        end
        @logger.info "info server has started"
        return true
      end

      def get_url_map
        urls = @config.get(URLS_KEY, nil)
        if urls.nil?
          urlmap = {"/jobs"   => Patriot::Worker::Servlet::JobServlet,
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
