module Patriot
  module Tool
    class BatchParser
      include Patriot::Util::Logger
      include Patriot::Util::DateUtil
      include Patriot::Util::Script

      def initialize(config)
        @config = config
        @logger = create_logger(config)
      end

      # parse PBC files and process commands specified in the PBC files
      # @param date [String] a date (yyyy-MM-dd) or range of dates (yyyy-MM-dd,yyyy-MM-dd)
      # @param paths [String|Array] paths to PBC files to be parsed
      # @param options parse options
      # @option options [String] :filter a regular expression to extract target commands
      # @yield block to process each command
      # @yieldparam cmd [Patriot::Command::Base] parsed command
      # @yieldparam source [Hash] location of the file has the command. (:path => <path to the file>)
      # @return an array of commands
      def process(date, paths, options = {}, &blk)
        dates = validate_and_parse_dates(date)
        commands = []
        dates.each do |d|
          $dt    = d
          $month = d.split('-').values_at(0,1).join('-')
          files  = paths.map {|path| get_batch_files(path, date)}.flatten
          if files.nil? || files.size == 0
            @logger.warn "ERROR: no pbc exists #{paths}"
            next
          end
          commands |= parse(files, options){|cmd, source| yield(cmd, source) if block_given?}
        end
        return commands
      end

      # parse PBC files and return a set of commands specified in the PBC files
      # @param files [String|Array] PBC files to be parsed
      # @param options parse options
      # @option options [String] :filter a regular expression to extract target commands
      # @param blk block to process each command
      # @return an array of commands
      def parse(files, options = {}, &blk)
        return if files.empty?
        commands = []
        filter = (options[:filter]) ? Regexp.new(options[:filter]) : nil

        files = [files] unless files.is_a?(Array)
        files.each do |file|
          parser = dsl_parser
          @logger.info "parsing #{file}"
          open(file) do |f|
            exp = f.read
            parser.parse(exp).flatten.each do |cmd|
              next unless filter.nil? || cmd.job_id =~ filter
              yield(cmd, {:path => file}) if block_given?
              commands << cmd
            end
          end
        end
        return commands
      end

      def dsl_parser
        # CommandGroup includes the Patriot::Parser module
        return Patriot::Command::CommandGroup.new(@config)
      end
    end
  end
end
