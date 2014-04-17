class ContentAggregator < GenericAggregator
  
  def thumbnail_info
    _members = member_ids()
    if _members.length > 1
      return {:url=>image_url("cul_scv_hydra/crystal/kmultiple.png"),:mime=>'image/png'}
    elsif _members.length == 0
      return {:url=>image_url("cul_scv_hydra/crystal/file.png"),:mime=>'image/png'}
    else
      member = ActiveFedora::Base.find(_members[0], :cast=>true)
      if member.respond_to? :thumbnail_info
        return member.thumbnail_info
      end
    end
    return {:url=>image_url("cul_scv_hydra/crystal/file.png"),:mime=>'image/png'}
  end
end
