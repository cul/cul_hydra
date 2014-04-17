require "active-fedora"
require "active_fedora_finders"
class JP2ImageAggregator < ResourceAggregator

  has_datastream :name => "SOURCE", :type=>::ActiveFedora::Datastream, :mimeType=>"image/jp2", :controlGroup=>'E'

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
