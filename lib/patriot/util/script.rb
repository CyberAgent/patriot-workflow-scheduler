module Patriot
  module Util
    # a module to find target files
    module Script
      include Patriot::Util::DateUtil

      # get target batch files from a given path
      # @param path [String] path to target directory
      # @param date [String] target date in '%Y-%m-%d'
      # @param opt [Hash]
      # @option opt :all [Boolean] force target all files
      # @return [Array<String>] a list of target files
      def get_batch_files(path, date, opt = {})
        return [path] if File.file?(path) && File.extname(path) == ".pbc" 
        files = []
        opt   = target_option(date, opt)
        files = Dir.glob("#{path}/**/*.pbc").find_all do |file|
          target_file?(file, opt)
        end
        return files
      end

      def target_option(date, opt = {})
        opt = {:all => false}.merge(opt)
        unless opt[:all]
          d = date.split('-')
          opt[:day] = true unless opt.has_key?(:day)
          unless opt.has_key?(:month)
            opt[:month] = date_add(date,1) =~ /[\d]{4}-[\d]{2}-01/ ? true : false 
          end
          unless opt.has_key?(:week)
            opt[:week]  = Date.new(d[0].to_i, d[1].to_i, d[2].to_i).wday
          end
        end
        return opt
      end
      private :target_option

      def target_file?(file, options)
        case
        when options[:all]               then true
        when file =~ /\/daily\//         then options[:day]
        when file =~ /\/monthly\//       then options[:month]
        when file =~ /\/weekly\/([0-6])/ then options[:week].to_s == $~[1]
        else true
        end
      end
      private :target_file?

    end
  end
end
