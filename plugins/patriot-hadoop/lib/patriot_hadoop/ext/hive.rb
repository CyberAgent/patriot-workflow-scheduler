module PatriotHadoop
  module Ext
    module Hive

      HIVE_MAX_ERROR_MSG_SIZE = 512

      include Patriot::Util::Logger
      include Patriot::Util::DBClient
      include Patriot::Util::System

      def self.included(cls)
        cls.send(:include, Patriot::Util::System)
      end

      class HiveException < Exception; end

      def execute_hivequery(hql_file, output_file, user = nil)
        command = "hive -f \"#{hql_file}\""
        unless user.nil?
          if user !~ /^[a-z_][a-z0-9_]{0,30}$/
            raise HiveException, "Invalid username" 
          end
          command = "sudo -u #{user} #{command}"
        end
        return _execute_hivequery_internal(command, output_file)
      end

      def _execute_hivequery_internal(command, output_file)
        so = execute_command(command) do |status, so, se|
          err_size = File.stat(se).size
          err_msg  = ""
          max_err_size = HIVE_MAX_ERROR_MSG_SIZE
          File.open(se) do |f|
            if err_size > max_err_size
              f.seek(-1 * max_err_size, IO::SEEK_END)
              err_msg = "\n(#{err_size - max_err_size} bytes are truncated)"
            end
            err_msg = "#{f.read}#{err_msg}"
          end
          raise HiveException, "#{command}\n#{err_msg}"
        end
        File.rename(so, output_file)
      end

      def _set_hive_property_prefix(props={})
        return "" if props.nil?
        return props.map{|k,v| "set #{k}=#{v};"}.join
      end

    end
  end
end
