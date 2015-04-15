require 'mysql2'
module Patriot
  module Util
    module DBClient
      def mysql2(dbconf = {})
        return Patriot::Util::DBClient::MySQL2Client.new(dbconf)
      end

      # NOT thread safe
      class MySQL2Client < Patriot::Util::DBClient::Base
        include Patriot::Util::DBClient

        def initialize(dbconf)
          conf = dbconf
          conf[:port] = dbconf[:port].to_i
          @connection = Mysql2::Client.new(conf)
        end

        def do_select(query)
          return @connection.query(query).map{|r| HashRecord.new(r)}
        end

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


        def do_insert(query)
          @connection.query(query)
          return @connection.last_id
        end

        def do_update(query)
          @connection.query(query)
          return @connection.affected_rows
        end

        def close()
          @connection.close unless @connection.nil?
        end

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
