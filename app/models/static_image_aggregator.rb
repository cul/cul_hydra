require "active-fedora"
class StaticImageAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator

  alias :file_objects :resources
  
  CUL_WIDTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth"
  CUL_LENGTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageLength"

  def route_as
    "image"
  end

  def index_type_label
    "PART"
  end
  
  def thumbnail_info
    candidate = nil
    max_dim = 251
    resources.each do |pid|
      resource = Resource.find(pid)
      width = resource.object_relations[CUL_WIDTH].first.to_i
      length = resource.object_relations[CUL_LENGTH].first.to_i
      max = (width > length) ? width : length
      if max_dim > max
        candidate = resource
        max_dim = max
      end
    end
    if candidate.nil?
      return {:url=>image_url("cul_scv_hydra/crystal/file_broken.png"),:mime=>'image/png'}
    else
      return {:url=>"#{ActiveFedora.fedora_config[:url]}/objects/#{candidate.pid}/datastreams/CONTENT/content",:mime=>candidate.datastreams['CONENT'].mimeType}
    end
  end
end
