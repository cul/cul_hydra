require "active-fedora"
require "hydra"
class GenericObject < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator::ModelMethods
  define_model_callbacks :create

  alias :file_objects :resources
  def create
    run_callbacks :create do
      super
    end
  end
  def route_as
    "multipartitem"
  end
end
