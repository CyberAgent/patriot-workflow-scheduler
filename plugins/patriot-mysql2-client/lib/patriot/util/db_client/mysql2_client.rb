require 'mysql2'
module Patriot
  module Util
    module DBClient
      # return a mysql2 client
      # @param dbconf [Hash] dbclient configuration
      def mysql2(dbconf = {})
        return Patriot::Util::DBClient::MySQL2Client.new(dbconf)
      end

      # NOT thread safe
      class MySQL2Client < Patriot::Util::DBClient::Base
        include Patriot::Util::DBClient

        # @param dbconf [Hash] dbclient configuration
        def initialize(dbconf)
          conf = dbconf
          conf[:port] = dbconf[:port].to_i
          @connection = Mysql2::Client.new(conf)
        end

        # @see Patriot::Util::DBClient::Base#do_select
        def do_select(query)
          return @connection.query(query).map{|r| HashRecord.new(r)}
        end

        # @see Patriot::Util::DBClient::Base#build_insert_query
        def build_insert_query(tbl, value, option = {})
          option = {:ignore => false}.merge(option)
          cols, vals = [], []
          value.each do |c,v|
            cols << c
            vals << quote(v)
          end
          if option[:ignore]
            return "INSERT IGNORE INTO #{tbl} (#{cols.join(',')}) VALUES (#{vals.join(',')})"
          else
            return "INSERT INTO #{tbl} (#{cols.join(',')}) VALUES (#{vals.join(',')})"
          end
        end

        # @see Patriot::Util::DBClient::Base#do_insert
        def do_insert(query)
          @connection.query(query)
          return @connection.last_id
        end

        # @see Patriot::Util::DBClient::Base#do_update
        def do_update(query)
          @connection.query(query)
          return @connection.affected_rows
        end

        # @see Patriot::Util::DBClient::Base#close
        def close()
          @connection.close unless @connection.nil?
        end

        # @see Patriot::Util::DBClient::Base#quote
        def quote(v)
          return 'NULL' if v.nil?
          return "'#{v.to_s}'" if v.is_a?(DateTime)
          val =  (v.is_a?(String) ? "'#{Mysql2::Client.escape(v)}'" : v)
          return val
        end

      end
    end
  end
end
