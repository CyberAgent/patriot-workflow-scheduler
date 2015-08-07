module Patriot
  module Command
    # a command which executes shell scripts
    class ShCommand < Patriot::Command::Base
      include Patriot::Util::System

      declare_command_name :sh

      command_attr :connector => '&&'
      command_attr :commands do |cmd, a, v|
        cmd.commands = v.is_a?(Array)? v : [v]
      end
      command_attr :name, :name_suffix
      validate_existence :name 

      # @see Patriot::Command::Base#job_id
      def job_id  
        return "#{command_name}_#{@name}_#{@name_suffix}"
      end

      # @see Patriot::Command::Base#configure
      def configure
        @name_suffix ||= _date_
        return self
      end

      # @see Patriot::Command::Base#description
      def description
        return @commands.join(@connector)
      end

      # @see Patriot::Command::Base#execute
      def execute
        @logger.info "start shell command "
        @commands.each do |c|
          execute_command(c)
        end
        @logger.info "end shell command "
      end
    end
  end
end
