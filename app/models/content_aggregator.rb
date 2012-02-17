require "active-fedora"
require "hydra"
class ContentAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
  define_model_callbacks :create
  after_create :aggregator!

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
