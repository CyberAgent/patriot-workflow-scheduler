module Patriot module Util
    module DBClient

      # @abstract base class for DB connection
      class Base

        # close this connection
        def close()
          raise NotImplementedError
        end

        # execute a given statment with this connection.
        # @param [String] stmt SQL statement to be executed
        # @param [Symbol] type type of execution (return type)
        # @return [Array] a list of records if the type is :select
        # @return [Integer] a id of last inserted record if the type is :insert
        # @return [Integer] the nubmer of affected rows if the type is :update
        def execute_statement(stmt, type = :select)
          method = "do_#{type}".to_sym
          begin
            return self.send(method, stmt)
          rescue => e
            raise "Failed to execute #{stmt} : Caused by (#{e})" 
          end
        end

        # insert value into a given table
        # @param [String] tbl the name of table where a row will be inserted
        # @param [Hash] value a Hash represents the inserted value
        # @param [Hash] opts
        # @option [Boolean] :ignore set true if set conflict strategy IGNORE (default false)
        # @return [Integer] a id of the last inserted record
        # @example the below invocation issues "INSERT INTO table (col) VALUES ('val')"
        #   insert('table', {:col => 'val'})
        def insert(tbl, value, opts = {})
          query = build_insert_query(tbl, value, opts)
          return execute_statement(query, :insert)
        end

        # create a insert statement for given arguments.
        # Subclasses can override this method if necessary
        # @param [String] tbl the name of table where a row will be inserted
        # @param [Hash] value a Hash represents the inserted value
        # @param [Hash] opts
        # @option [Boolean] :ignore set true if set conflict strategy IGNORE (default false)
        # @return [String] insert statement expression
        def build_insert_query(tbl, value, opts = {})
          opts = {:ignore => false}.merge(opts)
          cols, vals = [], []
          value.each do |c,v|
            cols << c
            vals << quote(v)
          end
          return "INSERT INTO #{tbl} (#{cols.join(',')}) VALUES (#{vals.join(',')})"
        end

        # The method which issues an insert statement
        # @param [String] query an insert statement
        # @return [Integer] a id of last inserted record if the type is :insert
        def do_insert(query)
          raise NotImplementedError
        end

        # select records from a table
        # @param [String] tbl the name of table where the records are searched
        # @param [Hash] cond a set of conditons for each attributes
        # @param [Hash] opts
        # @option [Integer] :limit LIMIT nubmer
        # @option [Integer] :offset OFFSET nubmer
        # @option [ARRAY] :items a list of output items
        # @return [Array] a list of records
        # @example the below invocation issues "SELECT * FROM table WHERE col = 'val'"
        #   select('table', {:col => 'val'})
        def select(tbl, cond = {}, opts = {})
          opts  = {:items => ['*']}.merge(opts)
          query = "SELECT #{opts[:items].join(', ')} FROM #{tbl} #{cond_exp(cond)}"
          query = "#{query} LIMIT #{opts[:limit]}" if opts.has_key?(:limit)
          query = "#{query} OFFSET #{opts[:offset]}" if opts.has_key?(:offset)
          return execute_statement(query, :select)
        end

        # The method which issues a select statement
        # @param [String] query a select statement
        # @return [Array] a list of records
        def do_select(query)
          raise NotImplementedError
        end

        # delete records from a table
        # @param [String] tbl the name of table from which records are deleted
        # @param [Hash] cond a set of conditions on deleted records
        # @return [Integer] the nubmer of affected rows
        # @example the below invocation issues "DELETE FROM table WHERE col = 'val'"
        #   delete('table', {:col => 'val'})
        def delete(tbl, cond)
          query = "DELETE FROM #{tbl} #{cond_exp(cond)}"
          return execute_statement(query, :update)
        end

        # update records of a table
        # @param [String] tbl the name of table in which records are updated
        # @param [Hash] new_val a set of new values
        # @param [Hash] cond a set of conditions on update records
        # @return [Integer] the nubmer of affected rows
        # @example the below invocation issues "UPDATE table SET col = 'val2' WHERE col = 'val1'"
        #   update('table', {:col => 'val2'}, {:col => 'val1'})
        def update(tbl, new_val, cond)
          query = "UPDATE #{tbl} SET #{value_exp(new_val)} #{cond_exp(cond)}"
          return execute_statement(query, :update)
        end

        # The method which issues a delete/update statement
        # @param [String] query a delete/update statement
        # @return [Integer] the nubmer of affected rows
        def do_update(query)
          raise NotImplementedError
        end

        def value_exp(val)
          raise "illegal type of value_exp #{val.class}" unless val.is_a?(Hash)
          return val.map{|k,v| v.nil? ? "#{k} = NULL" : "#{k} = #{quote(v)}"}.join(",")
        end

        def cond_exp(cond)
          cond = cond.map{|k,v| v.nil? ? "#{k} IS NULL" : "#{k} = #{quote(v)}"}.join(' AND ') if cond.is_a?(Hash)
          raise "illegal type of cond : #{cond.class}" unless cond.is_a?(String)
          cond = "WHERE #{cond}" unless cond == ""
          return cond
        end

        # quote a given value to use in SQL
        def quote(v)
          raise NotImplementedError
        end

      end

    end
  end
end
