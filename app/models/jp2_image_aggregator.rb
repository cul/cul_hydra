require "active-fedora"
require "hydra"
class JP2ImageAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::DatastreamCollections
  include ::ActiveFedora::Relationships
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator

  has_datastream :name => "SOURCE", :type=>::ActiveFedora::Datastream, :mimeType=>"image/jp2", :controlGroup=>'E'

  alias :file_objects :resources

  def route_as
    "zoomingimage"
  end

  def index_type_label
    "PART"
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super
    source = self.datastreams["SOURCE"]
    source.profile
    if source.controlGroup == 'E'
      solr_doc["rft_id"] = source.dsLocation
    else
      rc = ActiveFedora::RubydoraConnection.instance.connection
      url = rc.config["url"]
      uri = URI::parse(url)
      url = "#{uri.scheme}://#{uri.host}:#{uri.port}/fedora/objects/#{pid}/datastreams/SOURCE/content"
      solr_doc["rft_id"] = url
    end
    solr_doc
  end
end
