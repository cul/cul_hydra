module Cul
  module Scv
    module Fedora
      class FakeObject
        attr_accessor :pid
        def initialize(pid, isNew=false)
          @pid = pid
          @isNew = isNew
        end
        def new_record?
          @isNew
        end
        def connection
          Cul::Scv::Fedora.connection
        end    
        def repository
          Cul::Scv::Fedora.repository
        end
        def spawn(pid)
          s = FakeObject.new(pid)
          s.connection= connection
          s.repository= repository
          s
        end
        protected
        def connection=(connection); @connection = connection; end
        def repository=(repo); @repository = repo; end
      end
    end
  end
end