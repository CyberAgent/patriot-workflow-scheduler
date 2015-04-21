module Patriot
  module Util
    # namespace for parameter handling functions
    module Param

      # replace parameter values in command attribute valeus
      # @param attr_val an attribute value to be evaluated
      def eval_attr(attr_val)
        if attr_val.is_a?(Hash)
          entries = {}
          attr_val.each{|k,v| entries[eval_attr(k)] = eval_attr(v) }
          return entries
        elsif attr_val.is_a?(Array)
          return attr_val.map{|e| eval_attr(e)}
        elsif attr_val.is_a?(String)
          return eval_string_attr(attr_val)
        else
          # only evaluate attributes in String
          return attr_val
        end
      end

      # evaluate variables in a string expression
      # @param str [String] a string expression to be evaluated
      # @param vars [Hash] variables used in the evaluation
      # @return [String] a evaluated string expression
      def eval_string_attr(str, vars = {})
        s = StringScanner.new(str)
        s.scan(/(.*?)\#\{/m)
        # retrun immediatelly if variables are not contained
        return str unless s.matched?
        prefix = s[1]
        nest = 1 # depth of parenthesis
        var = "" # variable expression
        prev_rest = s.rest
        while nest > 0
          tmp = s.scan(/(.*?)[\{\}]/m) # for hash objects, etc
          if s.matched?
            if /.*?\{/ =~ tmp
              nest = nest + 1
              var << s[0]
            else 
              nest = nest - 1
              if nest >  0
                var << s[0]
              else
                # does not include the last parenthesis indicates end of the variable 
                var << s[1]
              end
            end
          end
          raise "infinte loop #{str} : rest #{s.rest} : #{nest}" if prev_rest == s.rest
          prev_rest = s.rest
        end
        # evaluate the variable
        var_binding = build_var_binding(vars)
        var_binding = binding if var_binding.nil?
        evaled_var = eval var, var_binding
        # farther variables are handled by next invocation
        return "#{prefix}#{evaled_var}#{eval_string_attr(prev_rest, vars)}"
      end

      def build_var_binding(vars)
        return nil if vars.empty?
        raise "illegal key var exist in #{vars.inspect}" if vars.has_key?('vars')
        assign_exps = [vars.map{|k,v| "#{k} = vars['#{k}']"}] | ["binding"]
        return eval assign_exps.join(";")
      end
      private :build_var_binding

    end
  end
end
