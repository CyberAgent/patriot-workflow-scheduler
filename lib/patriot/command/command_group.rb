module Patriot
  module Command 
    ## Patriot::Command::Baseを継承
    class CommandGroup < Base
      declare_command_name :command_group
      declare_command_name :job_group
      attr_accessor :subcommands

      def initialize(config)
        super
        @subcommands = []
      end

      def job_id
        raise "unsupported"
      end

      def add_subcommand(cmd)
        @subcommands << cmd
      end

      def serialize
        raise "Unsupported Exception"
      end

      def command_attrs
        []
      end

      def configure
        return @subcommands.map{|cmd|
          cmd.require @requisites
          cmd.produce @products
          cmd.build(@param)
        }.flatten
      end

      def execute
        @subcommands.each do |k,v|
          v.execute
        end
      end

    end
  end
end
