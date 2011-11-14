require "active-fedora"
require "hydra"
class DcDocument < ActiveFedora::Base
  include Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::ModelMethods
  alias :file_objects :resources
end
