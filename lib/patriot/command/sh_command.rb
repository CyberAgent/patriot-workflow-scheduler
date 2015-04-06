module Patriot
  module Command
    class ShCommand < Patriot::Command::Base
      include Patriot::Util::System

      declare_command_name :sh

      command_attr :connector => '&&'
      command_attr :commands do |cmd, a, v|
        cmd.commands = v.is_a?(Array)? v : [v]
      end
      volatile_attr :name, :name_suffix
      validate_existence :name 

      def job_id  
        return "#{command_name}_#{@name}_#{@name_suffix}"
      end

      def configure
        @name_suffix ||= $dt
        return self
      end

      def description
        return @commands.join(@connector)
      end

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
