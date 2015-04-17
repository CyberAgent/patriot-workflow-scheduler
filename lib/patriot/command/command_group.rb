module Patriot
  module Command 
    # define a group of jobs
    class CommandGroup < Base
      declare_command_name :command_group
      declare_command_name :job_group
      attr_accessor :subcommands

      # @param config [Patriot::Util::Config::Base]
      def initialize(config)
        super
        @subcommands = []
      end

      # add a command to this group
      # @param cmd [Patriot::Command::Base] a command to be added to this group
      def add_subcommand(cmd)
        @subcommands << cmd
      end

      # configure thie group.
      # pass the required/produced products and parameters to the commands in this group
      # @return [Array<Patriot::Command::Base>] a list of commands in this group
      def configure
        return @subcommands.map{|cmd|
          cmd.require @requisites
          cmd.produce @products
          cmd.build(@param)
        }.flatten
      end

      # execute each command in this group
      def execute
        @subcommands.each do |k,v|
          v.execute
        end
      end

    end
  end
end
