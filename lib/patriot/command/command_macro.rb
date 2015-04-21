module Patriot
  module Command
    # macros to be used for implmentation of command classes
    module CommandMacro

      # add module methods to DSL methods
      # @param command_module [Module] module defines methods for the use in DSL
      def add_dsl_function(command_module)
        class_eval{ include command_module } 
      end

      # declare DSL method name for defining the command
      # @param mth_name [String] the DSL method name
      # @param parent_cls [Class] parent command to which the new command is added
      # @param cmd_cls [Class]
      def declare_command_name(mth_name, parent_cls=Patriot::Command::CommandGroup, cmd_cls=self)
        parent_cls.class_eval do
          define_method(mth_name) do |&cmd_def|
            cmd = new_command(cmd_cls, &cmd_def)
            add_subcommand(cmd)
          end
        end
      end

      # declare command attributes to be able to use in DSL
      # @param attrs [String|Hash] attribute names or a Hash from attribute name to its default value
      # @yield block to preprocess attribute values
      # @yieldparam [Patriot::Command::Base] command instance
      # @yieldparam [String] attribute name
      # @yieldparam [String] passed value
      def command_attr(*attrs, &blk)
        @command_attrs = {} if @command_attrs.nil?
        default_values = {} 
        if attrs.size == 1 && attrs[0].is_a?(Hash)
          default_values = attrs[0] 
          attrs = default_values.keys
        end
        attrs.each do |a|
          raise "a reserved word #{a} is used as parameter name" if Patriot::Command::COMMAND_CLASS_KEY == a
          raise "#{a} is already defined" if self.instance_methods.include?(a)
          @command_attrs[a] = default_values[a] 
          define_method(a) do |*args|
            raise "illegal size of arguments (#{a} with #{args.inspect})" unless args.size == 1
            val = args[0]
            if block_given?
              yield(self, a, val) 
            else
              self.param a.to_s => val
            end
          end
          attr_writer a
        end
        return attrs
      end

      # declare command attributes for only internal use
      # @param attrs [String] attribute name
      def private_command_attr(*attrs)
        command_attr(*attrs) do |cmd, attr_name, attr_val|
          raise "only internal call is expected for #{attr_name}"
        end
      end

      # declare command attributes to be able to use in DSL
      # values of thes attributes are supposed to be used in {Patriot::Command::Base#do_configure}
      # and would not be serialized
      # @param attrs [String|Hash] attribute names or a Hash from attribute name to its default value
      # @yield block to preprocess attribute values
      # @yieldparam [Patriot::Command::Base] command instance
      # @yieldparam [String] attribute name
      # @yieldparam [String] passed value
      def volatile_attr(*attrs, &blk)
        @volatile_attrs = [] if @volatile_attrs.nil?
        attrs = command_attr(*attrs, &blk)
        attrs.each do |a|
          @volatile_attrs << a
        end
      end

      # @return [Hash] a Hash from attribute name to its value
      def command_attrs
        super_attrs = {}
        if self.superclass.respond_to?(:command_attrs)
          super_attrs = self.superclass.command_attrs
        end
        return super_attrs if @command_attrs.nil?
        return super_attrs.merge(@command_attrs)
      end

      # @return [Array] a list of volatile attribute names
      def volatile_attrs
        super_attrs = []
        if self.superclass.respond_to?(:volatile_attrs)
          super_attrs = self.superclass.volatile_attrs 
        end
        return super_attrs if @volatile_attrs.nil?
        return @volatile_attrs | super_attrs
      end

      # @return [Array] a array of attribute names which should be inclued in Job
      def serde_attrs
        return command_attrs.keys - volatile_attrs
      end

      # validate attriubte value
      # @param attrs attribute names to be validated
      # @yield logic which validates the value
      # @yieldreturn [Boolean] true if the value is valid, otherwise false
      def validate_attr(*attrs, &blk)
        raise "validation logic not given" unless block_given?
        unless blk.arity == 3
          raise "validation logic arguments should be (cmd, attr_name, attr_val)" 
        end
        @validation_logics = {} if @validation_logics.nil?
        attrs.each do |a|
          raise "#{a} is not command attr" unless command_attrs.include?(a)
          @validation_logics[a] = [] unless @validation_logics.has_key?(a)
          @validation_logics[a] << blk
        end
      end

      # check whether the attribute value is not nil
      # @see {validate_attribute_value}
      def validate_existence(*attrs)
        validate_attr(*attrs) do |cmd, a, v|
          !v.nil?
        end
      end

      # @return [Hash] a hash from attribute name to validation logic (Process)
      def validation_logics
        super_logics = {}
        if self.superclass.respond_to?(:volatile_attrs)
          super_logics = self.superclass.validation_logics 
        end
        return super_logics if @validation_logics.nil?
        return super_logics.merge(@validation_logics)
      end
    end
  end
end
