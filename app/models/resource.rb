require "active-fedora"
require "cul_image_props"
require "hydra"
require "mime/types"
require "uri"
class Resource < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model
  include Cul::Scv::Hydra::ActiveFedora::Model::Resource
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
  def index_type_label
    "FILE RESOURCE"
  end
  def to_solr(solr_doc = Hash.new, opts={})
    sdoc = super
    unless sdoc["extent_s"] || self.datastreams["CONTENT"].nil?
      sdoc["extent_s"] << self.datastreams["CONTENT"].size
    end
    sdoc
  end
end
