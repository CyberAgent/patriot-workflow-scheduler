# the root name space for this scheduler
module Patriot
  # a name space for commands
  module Command 
    module PostProcessor
      POST_PROCESSOR_CLASS_KEY   = "POST_PROCESSOR_CLASS"
      require 'patriot/command/post_processor/base'
      require 'patriot/command/post_processor/skip_on_fail'
    end
  end
end

