require "active-fedora"
require "hydra"
class DcDocument < ActiveFedora::Base
  include Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model
  alias :file_objects :resources
end
