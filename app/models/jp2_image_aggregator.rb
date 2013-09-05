require "active-fedora"
class JP2ImageAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
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
      solr_doc["rft_id_ss"] = source.dsLocation
    else
      rc = ActiveFedora::RubydoraConnection.instance.connection
      url = rc.config["url"]
      uri = URI::parse(url)
      url = "#{uri.scheme}://#{uri.host}:#{uri.port}/fedora/objects/#{pid}/datastreams/SOURCE/content"
      solr_doc["rft_id_ss"] = url
    end
    solr_doc
  end
  
  def thumbnail_info
    {:url => "#{ActiveFedora.fedora_config[:url]}/objects/#{pid}/methods/ldpd:sdef.Image/getView?max=250", :mime => 'image/jpeg'}
  end
end
