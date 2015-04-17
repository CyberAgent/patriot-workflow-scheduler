require 'rubygems'
require 'thor'

module Patriot
  # namespace for command line tools
  module Tool

    # new command can be added as follows
    # require 'patriot/tool/patriot_command'
    # module Hoge
    #   Patriot::Tool::PatriotCommand.class_eval do
    #     desc 'fuga', 'fuga description'
    #     def fuga
    #       puts 'fuga'
    #     end
    #   end
    # end
    class PatriotCommand < Thor
      include Patriot::Util::Config
      class_option :config,
          :aliases  => '-c',
          :type     => :string,
          :desc     => 'path to configuration file'
      no_tasks do 
        def exit_on_failure?
          return true
        end

        def symbolize_options(opts = {})
          symbolized_options = {}
          opts.each{|k,v| symbolized_options[k.to_sym] = v }
          return symbolized_options 
        end
      end
    end
  end
end

# command implementations
require 'patriot/tool/patriot_commands/execute'
require 'patriot/tool/patriot_commands/register'
require 'patriot/tool/patriot_commands/worker'
require 'patriot/tool/patriot_commands/worker_admin'
require 'patriot/tool/patriot_commands/validate'
require 'patriot/tool/patriot_commands/job'
require 'patriot/tool/patriot_commands/plugin'
require 'patriot/tool/patriot_commands/upgrade'

