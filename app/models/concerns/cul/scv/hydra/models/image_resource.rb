module Cul::Scv::Hydra::Models
  module ImageResource
    IMAGE_EXT = {"image/bmp" => 'bmp', "image/gif" => 'gif', "image/jpeg" => 'jpg', "image/png" => 'png', "image/tiff" => 'tif', "image/x-windows-bmp" => 'bmp', 'image/jp2' => 'jp2'}
    WIDTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_width))
    LENGTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_length))
    WIDTH_PREDICATE = ActiveFedora::Predicates.short_predicate("http://www.w3.org/2003/12/exif/ns#imageWidth").to_s
    LENGTH_PREDICATE = ActiveFedora::Predicates.short_predicate("http://www.w3.org/2003/12/exif/ns#imageLength").to_s
    EXTENT_PREDICATE = ActiveFedora::Predicates.short_predicate("http://purl.org/dc/terms/extent").to_s
    FORMAT_OF_PREDICATE = ActiveFedora::Predicates.short_predicate("http://purl.org/dc/terms/isFormatOf").to_s
    FORMAT_URI = RDF::URI("http://purl.org/dc/terms/format")

    DJATOKA_THUMBNAIL_PARMS = {
      "url_ver" => "Z39.88-2004",
      "svc_id" => "info:lanl-repo/svc/getRegion",
      "svc_val_fmt" => "info:ofi/fmt:kev:mtx:jpeg2000",
      "svc.format" => "image/jpeg",
      "svc.level" => "",
      "svc.rotate" => "0",
      "svc.scale" => "200",
      "svc.clayers" => ""
    }

    DJATOKA_BASE_URL = "http://iris.cul.columbia.edu:8888/resolve"

    def long
      @long_side ||= max(width(), length())
    end

    def width
      @width ||= begin
        ds = datastreams["content"]
        width = 0
        unless ds.nil? or rels_int.relationships(ds,:exif_image_width).blank?
          width = rels_int.relationships(ds,:exif_image_width).first.object.to_s.to_i
        end
        width = relationships(:image_width).first.to_s.to_i if width == 0
        width
      end
    end

    def length
      @length ||= begin
        ds = datastreams["content"]
        length = 0
        unless ds.nil? or rels_int.relationships(ds,:exif_image_length).blank?
          length = rels_int.relationships(ds,:exif_image_length).first.object.to_s.to_i
        end
        length = relationships(:image_length).first.to_s.to_i if length == 0
        length
      end
    end

    def zooming?
      zoom = rels_int.relationships(datastreams['content'],:foaf_zooming).first
      return zoom.object.to_s if zoom
      datastreams.each do |k,v|
        if v.mimeType =~ /image\/jp2$/i
          zoom = "info:fedora/#{k.dsid}"
        end
      end
      return zoom  
    end

    def thumbnail_info
      thumb = rels_int.relationships(datastreams['content'],:foaf_thumbnail).first
      if thumb
        t_dsid = thumb.object.to_s.split('/')[-1]
        t_url = "#{ActiveFedora.fedora_config.credentials[:url]}/objects/#{pid}/datastreams/#{t_dsid}/content"
        return {:url=>t_url,:mime=>datastreams[t_dsid].mimeType}
      elsif (zoom = self.zooming?)
        t_dsid = zoom.split('/')[-1]
        t_parms = DJATOKA_THUMBNAIL_PARMS.merge({"rft_id" => datastreams[t_dsid].dsLocation})
        url = "#{DJATOKA_BASE_URL}?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }"
        {:url => url, :mime => t_parms["svc.format"]}
      else
        return {:asset=>"cul_scv_hydra/crystal/file.png",:mime=>'image/png'}
      end
    end
  end
end