module Patriot
  module JobStore
    # a record stored in jobstore
    class Job

      attr_accessor :job_id, :update_id, :attributes

      def initialize(job_id)
        @job_id     = job_id
        @attributes = {
                        Patriot::Command::PRIORITY_ATTR => Patriot::JobStore::DEFAULT_PRIORITY,
                        Patriot::Command::STATE_ATTR    => Patriot::JobStore::JobState::INIT
                      }
      end

      def []=(k,v)
        raise "key #{k} should be string but #{k.class}" unless k.is_a?(String)
        @attributes[k] = v
      end

      def [](k)
        raise "key #{k} should be string but #{k.class}" unless k.is_a?(String)
        return @attributes[k]
      end

      def delete(k)
        raise "key #{k} should be string but #{k.class}" unless k.is_a?(String)
        return @attributes.delete(k)
      end

      def read_command(command)
        Patriot::Command::COMMON_ATTRIBUTES.each do |attr|
          value = command.instance_variable_get("@#{attr}".to_sym)
          self[attr] = value unless value.nil?
        end
        _to_stdobj(command).each{|k,v| self[k] = v}
      end

      # convert a given object to an object only includes standand objects can be converted to JSON.
      # in other words, convert Command instances in the object to hash
      def _to_stdobj(obj)
        if obj.is_a?(Patriot::Command::Base)
          hash = {}
          hash[Patriot::Command::COMMAND_CLASS_KEY] = obj.class.to_s.gsub(/::/, '.')
          obj.class.serde_attrs.each do |attr|
            value = obj.instance_variable_get("@#{attr}".to_sym)
            hash[attr.to_s] = _to_stdobj(value) unless value.nil?
          end
          return hash
        elsif obj.is_a?(Hash)
          hash = {}
          obj.each{|k,v| hash[k.to_s] = _to_stdobj(v)}
          return hash
        elsif obj.is_a?(Array)
          return obj.map{|e| _to_stdobj(e)}
        else
          return obj
        end
      end
      private :_to_stdobj

      def to_command(config)
        raise "configuration is not set" if config.nil?
        return _from_stdobj(self.attributes, config)
      end

      # convert corresponding objects in the given argument into Command instances.
      def _from_stdobj(obj, config)
        if obj.is_a?(Hash)
          if obj.has_key?(Patriot::Command::COMMAND_CLASS_KEY)
            cmd_cls = obj.delete(Patriot::Command::COMMAND_CLASS_KEY)
            cmd_cls = cmd_cls.split('.').inject(Object){|c,name| c.const_get(name)}
            cmd     = cmd_cls.new(config)
            obj.each do |k,v|
              cmd.instance_variable_set("@#{k}".to_sym, _from_stdobj(v, config))
            end
            return cmd
          else
            hash = {}
            obj.each{|k,v| hash[k] = _from_stdobj(v, config)}
            return hash
          end
        elsif obj.is_a?(Array)
          return obj.map{|e| _from_stdobj(e, config)}
        else
          return obj
        end
      end

      def filter_attributes(attrs)
        filtered = {}
        attrs.each{|a| filtered[a] = self[a]}
        return filtered
      end
    end
  end
end
