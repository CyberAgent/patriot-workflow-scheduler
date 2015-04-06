require "erb"
module Patriot
  module Command
    
    # namespace for DSL parser
    module Parser

      # create a command
      # @param cls [Class] class of the command
      # @yield block to set attributes to the command
      # @todo remove invoction of register_command by moving to the command_macro
      def new_command(cls, &blk)
        raise "configuration is not set" if @config.nil?
        command = cls.new(@config)
        @macros.each{|n,b| command.batch_macro(n,&b)} unless @macros.nil?
        command.instance_eval(&blk) if block_given?
        return command
      end

      # parse DSL by processing the DSL description as block
      # @return a list of command defined in the DSL description
      def parse(blk)
        self.instance_eval(blk)
        return self.build({})
      end

      # load macro to be able to be used in the DSL
      # @param macro_file [String] path to a macro file
      def load_macro(macro_file)
        macro_file = File.expand_path(macro_file,$home)
        @logger.info "loading macro file #{macro_file}" 
        open(macro_file){|f|
          self.instance_eval(f.read)
        }
      end

      # define macro.
      # this method is used in macro files
      # @param name name of the macro
      # @yieldreturn the result of the macro evaluation
      def batch_macro(name, &blk)
        raise "#{name} is invalid macro name (duplicate or defined method)" if respond_to?(name.to_sym)
        eigenclass = class << self
          self
        end
        @macros[name] = blk
        eigenclass.send(:define_method, name, &blk)
      end
        
      # import an ERB template
      # @param file [String] path to the ERB template
      # @param _vars [Hash] a hash from variable name to its value used in the ERB
      def import_erb_config(file, _vars)
        file = File.expand_path(file,$home)
        # set variables
        erb = _vars.map{|k,v| "<%#{k} = #{v.inspect}%>"}.join("\n")
        erb << "\n"

        # read the ERB
        exp=""
        open(file) do |f|
          erb << f.read
          exp = ERB.new(erb).result(binding)
        end
        begin
          self.instance_eval(exp)
        rescue => e
          @logger.error("failed to parse #{file}")
          @logger.error(erb)
          raise e
        end
      end
    end
  end
end

