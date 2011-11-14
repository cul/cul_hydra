require "active-fedora"
require "hydra"
class StaticImageAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator::ModelMethods
  define_model_callbacks :create
  after_create :aggregator!

  alias :file_objects :resources
  def create
    run_callbacks :create do
      super
    end
  end
  def route_as
    "image"
  end
end