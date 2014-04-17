class ResourceAggregator < ::ActiveFedora::Base
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::Models::Common
  include Cul::Scv::Hydra::Models::Aggregator
  include Cul::Scv::Hydra::Models::LinkableResources

  has_many :parts, :property => :cul_member_of, :class_name=>'Resource'

  def route_as
    "resource"
  end
  
  def index_type_label
    "PART"
  end
  
  def thumbnail_info
    return {:url=>image_url("cul_scv_hydra/crystal/file.png"),:mime=>'image/png'}
  end
end