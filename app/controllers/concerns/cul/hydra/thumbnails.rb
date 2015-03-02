require 'httpclient'
module Cul::Hydra::Thumbnails
  # some thumbnail urls
  NO_THUMB = "cul_scv_hydra/crystal/file.png"
  BROKEN_THUMB = "cul_scv_hydra/crystal/file_broken.png"
  COLLECTION_THUMB = "cul_scv_hydra/crystal/kmultiple.png"
  AUDIO_THUMB = "cul_scv_hydra/crystal/sound.png"
  # some rel predicates
  FORMAT = "http://purl.org/dc/elements/1.1/format"
  MEMBER_OF = "http://purl.oclc.org/NET/CUL/memberOf"
  HAS_MODEL = "info:fedora/fedora-system:def/model#hasModel"
  IMAGE_WIDTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth"
  IMAGE_LENGTH = "http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageLength"

  def show
    pid = params[:id].split(/@/)[0]
    get_by_pid(pid)
  end

  def get_by_pid(pid)
    r_obj = ActiveFedora::Base.find(pid, :cast=>true)
    
    if r_obj.respond_to? :thumbnail_info
      url = r_obj.thumbnail_info
    else
      url = {:asset=>(COLLECTION_THUMB),:mime=>'image/png'}
    end
    if url[:asset]
      #url = {:url=>asset_url(COLLECTION_THUMB),:mime=>'image/png'}
      #redirect_to asset_url(url[:asset]).to_s, status: 302
      #return
    end
    Rails.logger.debug "thumbnail #{url[:url] || url[:asset]} #{url[:mime]}"
    filename = pid + '.' + url[:mime].split('/')[1].downcase
    h_cd = "filename=""#{CGI.escapeHTML(filename)}"""
    headers.delete "Cache-Control"
    headers["Content-Disposition"] = h_cd
    headers["Content-Type"] = url[:mime]
   
    if url[:asset]
      full_path = Rails.application.assets.resolve(url[:asset]).to_path
      render :status => 200, :text => File.read(full_path)
      return
    elsif url[:url].to_s =~ /^https?:/
      cl = http_client
      render :status => 200, :text => cl.get_content(url[:url])
      return
    else
      render :status => 200, :text => File.read(url[:url])
      return
    end
  end

  def jp2_thumbnail(pid)
    {:url => ActiveFedora.fedora_config.credentials[:url] + '/objects/' + pid + '/methods/ldpd:sdef.Image/getView?max=250', :mime => 'image/jpeg'}
  end

  def pid_from_uri(uri)
    return uri.sub(/info:fedora\//,'')
  end
  
end