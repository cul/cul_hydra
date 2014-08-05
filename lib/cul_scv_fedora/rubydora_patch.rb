module Cul
  module Scv
    module Fedora
      module RubydoraPatch
        def find_by_itql query, options = {}
          begin
          	self.risearch(query, {:lang => 'itql'}.merge(options))
          rescue Exception => e
          	logger.error e if defined?(logger)
          	"{\"results\":[]}"
          end
        end
      end
    end
  end
end
