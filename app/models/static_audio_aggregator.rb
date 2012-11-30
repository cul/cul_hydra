require "active-fedora"
class StaticAudioAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator

  alias :file_objects :resources

  def route_as
    "audio"
  end
  
  def index_type_label
    "PART"
  end
  
  def thumbnail_info
    return {:url=>image_url("cul_scv_hydra/crystal/mp3.png"),:mime=>'image/png'}
  end
end
