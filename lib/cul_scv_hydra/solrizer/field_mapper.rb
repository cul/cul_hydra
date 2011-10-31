require 'solrizer'
module Cul::Scv::Hydra::Solrizer
class FieldMapper < Solrizer::FieldMapper
  alias_method(:orig_solr_name_and_mappings, :solr_name_and_mappings)

  def self.default
    if defined?(Rails.root) && !Rails.root.nil?
      config_path = File.join(Rails.root, "config", "solr_mappings.yml")
    end
    # Default to using the config file within the gem 
    if !File.exist?(config_path.to_s)
      config_path = File.join(File.dirname(__FILE__), "..", "..", "..", "config", "solr_mappings.yml")
    end
    self.load_mappings(config_path)
    logger.info("FieldMapper: loading field name mappings from #{File.expand_path(config_path)}")
    self.new
  end

# This is an override of a private method in the base class, and will have to be monitored for changes
  def solr_name_and_mappings(field_name, field_type, index_type)
    if index_type == :textable
      result = orig_solr_name_and_mappings(field_name, field_type, :searchable)
      result[0]  = 'text'
      return result
    else
      orig_solr_name_and_mappings(field_name, field_type, index_type)
    end
  end
end
end
