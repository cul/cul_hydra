require "active-fedora"
require "hydra"
class DcDocument < ActiveFedora::Base
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  alias :file_objects :resources
end
