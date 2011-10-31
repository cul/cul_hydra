module Cul::Scv::Hydra::Solrizer
# This class uses a yaml map to translate field values for solr
class ValueMapper
def self.load_value_maps(config_path=nil)
    if config_path.nil?
      if defined?(Rails.root) && !Rails.root.nil?
        config_path = File.join(Rails.root, "config", "solr_value_maps.yml")
      end
      # Default to using the config file within the gem
      if !File.exist?(config_path.to_s)
        config_path = File.join(File.dirname(__FILE__), "..", "..", "..", "config", "solr_value_maps.yml")
      end
    end
    logger.info("ValueMapper: loading field value maps from #{File.expand_path(config_path)}")
    YAML::load(File.open(config_path))
  end

  def self.default_value_maps
    @@value_maps ||= self.load_value_maps
  end
  # Instance methods

  def initialize(value_maps=nil)
    @value_maps = value_maps || Cul::Scv::Hydra::Solrizer::ValueMapper.default_value_maps
  end
  def solr_value(map_key, value_key)
    return value_key unless @value_maps.has_key? map_key
    if value_key.is_a? Array
      value_key.collect{ |val| @value_maps[map_key].fetch(val, val) }
    else
      @value_maps[map_key].fetch(value_key, value_key)
    end
  end
end
end
