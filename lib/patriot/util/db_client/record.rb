
module Patriot
  module Util
    module DBClient

      # a class for abstracting access to records
      # sub classes of this class should provide accessers for columns or select items
      # (e.g. overwrite method_missing)
      class Record

        # get serial id of this record
        def get_id
          raise NotImplementedError
        end

        # convert this record to hash 
        # ==== Args
        #   keys : attributes included in the returned hash
        def to_hash(keys)
          raise NotImplementedError
        end
      end
    end
  end
end

