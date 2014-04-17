require "active-fedora"
require "active_fedora_finders"
class StaticImageAggregator < ResourceAggregator
  
  CUL_WIDTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth"
  CUL_LENGTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageLength"

  def route_as
    "image"
  end

  def index_type_label
    'PART'
  end

  def thumbnail_info
    candidate = nil
    max_dim = 251
    resources.each do |pid|
      resource = Resource.find(pid)
      if max_dim > resouce.long
        candidate = resource
        max_dim = resource.long
      end
    end
    if candidate.nil?
      return {:url=>image_url("cul_scv_hydra/crystal/file_broken.png"),:mime=>'image/png'}
    else
      return {:url=>"#{ActiveFedora.fedora_config[:url]}/objects/#{candidate.pid}/datastreams/CONTENT/content",:mime=>candidate.datastreams['CONENT'].mimeType}
    end
  end
end
