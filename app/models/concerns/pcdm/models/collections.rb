module Pcdm::Models::Collections
  extend ActiveSupport::Concern
  def compose_from(*collections)
  	collections = collections.map {|c| (c.is_a? String) ? ActiveFedora::Base.find(c) : c }
  	self.structMetadata.merge(*collections.map {|c| c.structMetadata})
  end
end