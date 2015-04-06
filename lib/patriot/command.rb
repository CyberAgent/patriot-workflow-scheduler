module Patriot
  module Command 
    COMMAND_CLASS_KEY   = "COMMAND_CLASS"

    REQUISITES_ATTR     = "requisites"
    PRODUCTS_ATTR       = "products"
    STATE_ATTR          = "state"
    PRIORITY_ATTR       = "priority"
    EXEC_NODE_ATTR      = "exec_node"
    EXEC_HOST_ATTR      = "exec_host"
    START_DATETIME_ATTR = "start_datetime"
    SKIP_ON_FAIL_ATTR   = "skip_on_fail"

    COMMON_ATTRIBUTES = [
      REQUISITES_ATTR,
      PRODUCTS_ATTR,
      STATE_ATTR,
      PRIORITY_ATTR,
      EXEC_NODE_ATTR,
      EXEC_HOST_ATTR,
      START_DATETIME_ATTR,
      SKIP_ON_FAIL_ATTR
    ]

    # return value of execute()
    module ExitCode
      SUCCEEDED = 0
      FAILED    = 1
      SKIPPED   = -1
    end

    require 'patriot/command/parser'
    require 'patriot/command/command_macro'
    require 'patriot/command/base'
    require 'patriot/command/command_group'
    require 'patriot/command/composite'
    require 'patriot/command/sh_command'
  end
end

