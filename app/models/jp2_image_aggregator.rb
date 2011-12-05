require "active-fedora"
require "hydra"
class JP2ImageAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator::ModelMethods

  has_datastream :name => "SOURCE", :type=>::ActiveFedora::Datastream, :mimeType=>"image/jp2", :controlGroup=>'E'

  define_model_callbacks :create
  after_create :aggregator!

  alias :file_objects :resources
  def create
    run_callbacks :create do
      super
    end
  end
  def route_as
    "image/zooming"
  end
  def index_type_label
    "PART"
  end
end
