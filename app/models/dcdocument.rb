require "active-fedora"
require "hydra"
class DcDocument < ActiveFedora::Base
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model
  alias :file_objects :resources
end
