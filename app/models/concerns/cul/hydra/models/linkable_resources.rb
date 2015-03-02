module Cul::Hydra::Models::LinkableResources
  include Cul::Hydra::Fedora::UrlHelperBehavior
  # so as to avoid including all the url hepers via:
  ## include Rails.application.routes.url_helpers
  # we are just going to delegate
  delegate :fedora_content_path,  :to => 'Rails.application.routes.url_helpers'
  delegate :cache_path,  :to => 'Rails.application.routes.url_helpers'

  def http_client
    unless @http_client
      @http_client ||= HTTPClient.new
      @http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      uname = Cul::Hydra::Fedora.repository.config[:user]
      pwd = Cul::Hydra::Fedora.repository.config[:password]
      @http_client.set_auth(nil, uname, pwd)
    end
    @http_client
  end

  def linkable_resources
    r = self.parts(:response_format => :solr)
    return [] if r.blank?
    members = r.collect {|hit|
      SolrDocument.new(hit)
    }
    members.delete_if { |sd| (sd[:has_model_ssim] & ["info:fedora/ldpd:Resource"]).blank? }
    case self.route_as
    when "zoomingimage"
      results = members.collect {|doc| image_resource(doc)}
      base_id = self.pid
      url = fedora_ds_url(base_id, 'SOURCE') + '/content'
      head_req = http_client().head(url)
      file_size = head_req.header["Content-Length"].first.to_i
      results << {
        :dimensions => "Original",
        :mime_type => "image/jp2",
        :uri=>base_id, :block=>"SOURCE", :filename=>base_id + "_source.jp2",
        :content_models=>[]}
    when "audio"
      results = members.collect {|doc| audio_resource(doc)}
    when "image"
      results = members.collect {|doc| image_resource(doc)}
    else
      raise "Unknown format #{self.route_as}"
    end
    return results
  end

  def basic_resource(document)
    res = {}
    res[:pid] = document["id"]
    res[:dsid] = "CONTENT"
    res[:mime_type] = document["dc_format_ssm"] ? document["dc_format_ssm"].first : "application/octect-stream"
    res[:content_models] = document["has_model_ssim"]
    res[:file_size] = document["extent_ssim"].first.to_i
    res[:size] = (document["extent_ssim"].first.to_i / 1024).to_s + " Kb"
    res
  end

  def image_resource(document)
    res = basic_resource(document)
    if document["image_width_ssim"]
      res[:dimensions] = document["image_width_ssim"].first + " x " + document["image_length_ssim"].first
      res[:width] = document["image_width_ssim"].first
      res[:height] = document["image_length_ssim"].first
    else
      res[:dimensions] = "? x ?"
      res[:width] = "0"
      res[:height] = "0"
    end
    base_id = document["id"]
    base_filename = base_id.gsub(/\:/,"")
    img_filename = base_filename + "." + document["dc_format_ssm"].first.gsub(/^[^\/]+\//,"")
    res[:filename] = img_filename
    res[:block] = "CONTENT"
    res[:mime_type] = document["dc_format_ssm"] ? document["dc_format_ssm"].first : "application/octect-stream"
    res[:content_models] = document["has_model_ssim"]
    res[:file_size] = document["extent_ssim"].first.to_i
    res[:size] = (document["extent_ssim"].first.to_i / 1024).to_s + " Kb"
    res[:uri] = base_id
    res
  end

  def audio_resource(document)
    res = basic_resource(document)
    base_id = document["id"]
    base_filename = base_id.gsub(/\:/,"")
    if res[:mime_type] =~ /wav/
      ext = 'wav'
    elsif res[:mime_type] =~ /mpeg/
      ext = 'mp3'
    else
      ext = 'bin'
    end
    filename = base_filename + "." + ext
    dc_filename = base_filename + "_dc.xml"
    res[:uri] = base_id
    res[:block] = "CONTENT"
    res[:filename] = filename
    res[:dc_path] = fedora_content_path(:download_method=>"show_pretty", :uri=>base_id, :block=>"DC", :filename=>dc_filename)
    res[:mime_type] = document["dc_format_ssm"] ? document["dc_format_ssm"].first : "application/octect-stream"
    res[:content_models] = document["has_model_ssim"]
    res[:file_size] = document["extent_ssim"].first.to_i
    res[:size] = (document["extent_ssim"].first.to_i / 1024).to_s + " Kb"
    res
  end

end
