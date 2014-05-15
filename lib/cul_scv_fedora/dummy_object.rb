module Cul
  module Scv
    module Fedora
      class DummyObject
        attr_accessor :pid
        def initialize(pid, isNew=false)
          @pid = pid
          @isNew = isNew
        end
        def new_record?
          @isNew
        end
        def new_record=(val)
          @isNew = val
        end
        def internal_uri
          @uri ||= "info:fedora/#{@pid}"
        end
        def connection
          Cul::Scv::Fedora.connection
        end    
        def repository
          Cul::Scv::Fedora.repository
        end
        def spawn(pid)
          s = DummyObject.new(pid, @isNew)
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