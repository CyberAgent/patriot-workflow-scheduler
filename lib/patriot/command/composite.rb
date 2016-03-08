module Patriot
  module Command
    # a command which is composed of multiple sub commands
    class CompositeCommand < Patriot::Command::CommandGroup
      declare_command_name :composite_command
      declare_command_name :composite_job
      private_command_attr :contained_commands => []
      command_attr :name, :name_suffix

      # @return [String] the identifier of this composite command
      # @see Patriot::Command::Base#job_id
      def job_id
        return "#{command_name}_#{@name}_#{@name_suffix}"
      end

      # @see Patriot::Command::Base#description
      def description
        first_job = @contained_commands.first
        first_job = first_job.description unless first_job.nil?
        return "#{first_job} ... (#{@contained_commands.size} jobs)"
      end

      # configure this composite command.
      # pull up required/produced products from the sub commands
      # @see Patriot::Command::Base#configure
      def configure
        @name_suffix ||= _date_
        # don't do flatten to handle nested composite commands
        @subcommands.map do |cmd|
          cmd = cmd.clone
          cmd.build(@param).each do |cmd|
            _validate_command(cmd)
            require cmd['requisites']
            produce cmd['products']
            @contained_commands << cmd
          end
        end
        return self
      end

      # execute the contained commands
      # @see Patriot::Command::Base#execute
      def execute
        @contained_commands.each do |c|
          c.execute
        end
      end

      # @private
      # validate command
      # @param [Patriot::Command::Base] cmd
      def _validate_command(cmd)
        if !cmd['post_processors'].nil?
          raise 'you cannot set "post_processor" at subcommand of composite_job\'s ' \
            + "\n" + 'name: ' + cmd['name'] \
            + "\n" + 'command: ' + cmd['commands'].to_s
        end
      end
      private :_validate_command

    end
  end
end
