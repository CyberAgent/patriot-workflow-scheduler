module Patriot
  module Command
    module PostProcessor

      # The base class of every post processor
      class Base

        # declare DSL method name for adding a post processor
        # @param mth_name [String] the DSL method name
        # @param parent_cls [Class<Patriot::Command::Base>] parent command in which the post porcessor is available
        # @param processor_cls [Class<Patriot::Command::PostProcessor::Base] the class of the post processor
        def self.declare_post_processor_name(mth_name, parent_cls=Patriot::Command::Base, processor_cls=self)
          parent_cls.class_eval do
            define_method(mth_name) do |processor_props = {}|
              pp = processor_cls.new(processor_props)
              add_post_processor(pp)
            end
          end
        end

        attr_accessor :props

        # @param props [Hash] properties of this post processor
        def initialize(props = {})
          validate_props(props)
          @props = props
        end

        def validate_props(props)
        end

        def process(cmd, worker, exit_code)
          case exit_code.to_i
          when Patriot::Command::ExitCode::SUCCEEDED then process_success(cmd, worker)
          when Patriot::Command::ExitCode::FAILED    then process_failure(cmd, worker)
          end
        end

        def process_success(cmd, worker)
        end

        def process_failure(cmd, worker)
        end

      end
    end
  end
end


