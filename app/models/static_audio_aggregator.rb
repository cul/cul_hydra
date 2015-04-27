require "active-fedora"
require "active_fedora_finders"
class StaticAudioAggregator < ResourceAggregator

  def route_as
    "audio"
  end
  
  def thumbnail_info
    return {:url=>image_url("cul_hydra/crystal/mp3.png"),:mime=>'image/png'}
  end
end
