require "active-fedora"
require "cul_image_props"
require "hydra"
require "mime/types"
require "uri"
class Resource < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Resource::ModelMethods
  define_model_callbacks :create
  after_create :resource!

  alias :file_objects :resources
  def create
    run_callbacks :create do
      super
    end
  end
  def route_as
    "resource"
  end
end
