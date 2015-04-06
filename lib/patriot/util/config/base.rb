module Patriot
  module Util
    module Config
      class Base
        # get value for the specified key
        # @param [String] key
        # @param [Object] default default value
        # @return [Object] the value for the ke
        def get(key, default=nil)
          raise NotImplementedError
        end

        # get path where this configuration is loaded
        # @return [String] path to the file
        def path
          raise NotImplementedError
        end
      end
    end
  end
end
