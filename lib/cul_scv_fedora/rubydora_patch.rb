module Cul
  module Scv
    module Fedora
      module RubydoraPatch
        def find_by_itql query, options = {}
          self.risearch(query, {:lang => 'itql'}.merge(options))
        end
      end
    end
  end
end