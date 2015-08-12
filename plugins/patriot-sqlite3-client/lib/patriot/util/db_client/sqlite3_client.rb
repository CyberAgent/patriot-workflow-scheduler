require 'sqlite3'
module Patriot
  module Util
    module DBClient
      # get an sqlite3 client
      # @param dbconf [Hash] dbclient configuration
      def sqlite3(dbconf = {})
        return Patriot::Util::DBClient::SQLite3Client.new(dbconf)
      end

      # NOT thread safe
      class SQLite3Client < Patriot::Util::DBClient::Base

        # @param dbconf [Hash] dbclient configuration
        def initialize(dbconf)
          db = dbconf[:database]
          db = File.join($home, db) unless db.start_with?("/")
          @connection = SQLite3::Database.new(dbconf[:database], :results_as_hash => true)
        end

        # @see Patriot::Util::DBClient::Base#do_select
        def do_select(query)
          return @connection.execute(query).map{|r| HashRecord.new(r)}
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
            return "INSERT OR IGNORE INTO #{tbl} (#{cols.join(',')}) VALUES (#{vals.join(',')})"
          else
            return "INSERT INTO #{tbl} (#{cols.join(',')}) VALUES (#{vals.join(',')})"
          end
        end

        # @see Patriot::Util::DBClient::Base#do_insert
        def do_insert(query)
          @connection.execute(query)
          return @connection.last_insert_row_id
        end

        # @see Patriot::Util::DBClient::Base#do_update
        def do_update(query)
          @connection.execute(query)
          return @connection.changes
        end

        # @see Patriot::Util::DBClient::Base#do_close
        def close()
          @connection.close unless @connection.nil?
        end

        # @see Patriot::Util::DBClient::Base#quote
        def quote(v)
          return 'NULL' if v.nil?
          return "'#{v.to_s}'" if v.is_a?(DateTime) || v.is_a?(Time)
          return (v.is_a?(String) ? "'#{v.gsub(/'/,"''")}'" : v)
        end

      end
    end
  end
end
