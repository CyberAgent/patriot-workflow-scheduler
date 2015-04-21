require 'rubygems/installer'
require 'rubygems/version_option'
require 'rubygems/remote_fetcher'
require 'rubygems/dependency_installer'
require 'fileutils'

module Patriot
  # a name space for controllers which encapsulate complicated operations
  module Controller
    # Controller class for remote management of workers
    class PackageController
      include Patriot::Util::Config
      include Patriot::Util::Logger

      # constructor
      # @param config [Patriot::Util::Config::Base] configuration of this controller
      def initialize(config)
        @config = config
        @logger = create_logger(config)
        @plugin_dir = config.get(Patriot::Util::Config::PLUGIN_DIR_KEY, Patriot::Util::Config::DEFAULT_PLUGIN_DIR)
        @plugin_dir = File.expand_path(@plugin_dir, $home)
      end

      # upgrade deployment
      def upgrade(pkg = 'patriot-workflow-scheduler')
        # upgrade plugins
        plugins = @config.get(Patriot::Util::Config::PLUGIN_KEY, [])
        plugins = [plugins] unless plugins.is_a?(Array)
        plugins.each{|plugin| install_plugin(plugin, {:force => true})}

        # upgrade core package
        dependency = Gem::Dependency.new(pkg || 'patriot-workflow-scheduler')
        path = dependency.name =~ /\.gem$/i ? dependency.name : Gem::RemoteFetcher.fetcher.download_to_cache(dependency) 
        installed_dir = Gem::Installer.new(path).dir
        installer = Gem::DependencyInstaller.new
        @logger.info "upgrade to #{dependency}"
        installer.install path

        public_dir = File.join(installed_dir, "skel", "public")
        @logger.info "copy #{public_dir} to  #{$home}"
        FileUtils.cp_r(public_dir, $home)
        FileUtils.cp(File.join(installed_dir, 'bin', 'patriot'), File.join($home, 'bin', 'patriot'))

      end

      # install plugin to plugin directory
      # @param [String] plugin name of the plugin
      # @param opts
      # @option [Boolean] :force set true to overwrite the installation
      def install_plugin(plugin, opts = {})
        @logger.info "install #{plugin}"
        dependency = Gem::Dependency.new plugin, opts[:version]
        path = dependency.name =~ /\.gem$/i ? dependency.name : Gem::RemoteFetcher.fetcher.download_to_cache(dependency) 
        raise "Gem '#{plugin}' not fetchable."  unless path
        basename = File.basename path, '.gem'
        # remvoe version
        basename = basename.gsub(/-[\d]+\.[\d]+\.[\d]+$/, "")
        target_dir = File.join(@plugin_dir, basename)
        if opts[:force] == true
          @logger.info "remove old #{target_dir}"
          FileUtils.rm_r target_dir if File.exist?(target_dir)
        else
          raise "#{target_dir} alrady exist" if File.exist?(target_dir)
        end
        FileUtils.mkdir_p target_dir
        if opts[:unpack]
          installer = Gem::Installer.new(path, :unpack=>true)
          installer.unpack target_dir
        else
          installer = Gem::DependencyInstaller.new
          installer.install path
          installed_dir = Gem::Installer.new(path).dir
          init_rb = File.join(installed_dir, "init.rb")
          FileUtils.cp(init_rb, target_dir)
        end
        @logger.info "#{path} installed: #{target_dir}'"
      end

    end
  end
end
