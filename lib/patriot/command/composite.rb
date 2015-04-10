module Patriot
  module Command
    ##  inherit GroupedCommand so that any commands are available in a composite command
    class CompositeCommand < Patriot::Command::CommandGroup 
      declare_command_name :composite_command 
      declare_command_name :composite_job 
      private_command_attr :contained_commands => []
      volatile_attr :name, :name_suffix

      def job_id  
        return "#{command_name}_#{@name}_#{@name_suffix}"
      end

      def description
        first_job = @contained_commands.first
        first_job = first_job.description unless first_job.nil?
        return "#{first_job} ... (#{@contained_commands.size} jobs)"
      end

      def configure
        @name_suffix ||= _date_
        # don't do flatten to handle nested composite commands
        @subcommands.map do |cmd|
           cmd.build(@param).each do |cmd|
            require cmd['requisites']
            produce cmd['products']
            @contained_commands << cmd
          end
        end
        return self
      end

      def execute
        @contained_commands.each do |c|
          c.execute
        end
      end 

    end
  end
end
