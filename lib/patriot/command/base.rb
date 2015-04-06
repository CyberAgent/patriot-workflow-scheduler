require 'active_support/core_ext/hash/deep_merge'
module Patriot
  module Command
    class Base
      include Patriot::Command::Parser
      include Patriot::Util::Param
      include Patriot::Util::DateUtil
      include Patriot::Util::Logger

      class << self
        include Patriot::Command::CommandMacro
      end

      attr_accessor :parser, :test_mode

      # comman attributes handled distinctively (only effective in top level commands)
      volatile_attr :requisites, :products, :priority, :start_after, :exec_date, :exec_node, :exec_host, :skip_on_fail

      def initialize(config)
        @config     = config
        @logger     = create_logger(config)
        @param      = {}
        @requisites = []
        @products   = []
        @macros     = {}
        @test_mode  = false
      end

      def to_job
        job = Patriot::JobStore::Job.new(self.job_id)
        job.read_command(self)
        return job
      end

      def [](key)
        return instance_variable_get("@#{key}".to_sym)
      end

      def job_id
        raise NotImplementedError
      end

      # set default command name
      # replace :: to handle in JSON format
      def command_name
        return self.class.to_s.split("::").last.downcase.gsub(/command/,"")
      end

      def require(requisites)
        return if requisites.nil?
        @requisites |= requisites.flatten
      end

      def produce(products)
        return if products.nil?
        @products |= products.flatten
      end

      def skip
        param 'state' => Patriot::JobStore::JobState::SUCCEEDED
      end

      def suspend
        param 'state' => Patriot::JobStore::JobState::SUSPEND
      end

      def skip_on_fail?
        return @skip_on_fail == 'true' || @skip_on_fail == true
      end

      # start datetime of this command.
      # This command should be executed after the return value of this method
      # @return [DateTime]
      def start_date_time
        return nil if @exec_date.nil? && @start_after.nil?
        # set tomorrow as default
        date = (@exec_date || date_add($dt, 1)).split("-").map(&:to_i)
        # set midnight as default
        time = (@start_after || "00:00:00").split(":").map(&:to_i)
        return DateTime.new(date[0], date[1], date[2], time[0], time[1], time[2])
      end

      # update parameters with a given hash.
      # If the hash includes keys which values have already been defined,
      # the value for the key is replaced with the new value.
      # @param _param [Hash] a hash from attribute name to its value
      def param(_param)
        @param = @param.deep_merge(_param)
      end

      # build this command as executables
      # @param _param [Hash] default parameter
      def build(_param={})
        @param = _param.deep_merge(@param)
        init_param
        @start_datetime = start_date_time
        cmds = configure()
        cmds = [cmds] unless cmds.is_a?(Array)
        cmds.each(&:validate_command_attrs)
        return cmds.flatten
      end

      # initialize command attributes
      def init_param
        # set parameter value to instance variable
        @param.each do |k,v|
          raise "a reserved word #{k} is used as parameter name" if Patriot::Command::COMMAND_CLASS_KEY == k
          raise "#{k} is already used in #{self.job_id}" unless instance_variable_get("@#{k}".to_sym).nil?
          # don't evaluate here since all parameters are not set to instance variables
          instance_variable_set("@#{k}".to_sym,v)
        end

        # evaluate command attributes using parameters (instance variables)
        self.class.command_attrs.each { |a, d| configure_attr(a, d) }
      end
      protected :init_param

      # configure a command attribute and set as an instance variable
      # @param attr [String] an attribute name to be configured
      # @param default_value default value of the attribute
      def configure_attr(attr, default_value = nil)
        v = instance_variable_get("@#{attr}".to_sym)
        v = default_value if v.nil?
        instance_variable_set("@#{attr}".to_sym, eval_attr(v))
      end

      # a hook method to implement comand-specific configuration
      def configure
        return self
      end

      # validate values of command attributes
      # @see Patriot::Command::CommandMacro#validate_attr
      def validate_command_attrs
        self.class.validation_logics.each do |attr, logics|
          val = self.instance_variable_get("@#{attr}".to_sym)
          logics.each do |l|
            unless l.call(self, attr, val)
              raise "validation error : #{attr}=#{val} (#{self.class})" 
            end
          end
        end
      end

      # add a sub command
      # @raise if sub command is not supported
      def add_subcommand
        raise "sub command is not supported"
      end

      # @return description of this command
      def description
        self.job_id
      end

      # execute this command
      def execute()
        raise NotImplementedError
      end

    end
  end
end


