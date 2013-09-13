require 'solrizer'
module Solrizer::DefaultDescriptors
  def self.date_sortable
    @date_sortable ||= Solrizer::Descriptor.new(:date, :stored, :indexed, converter: date_sortable_converter)
  end

  # Produces the field name 'all_text_timv'
  def self.textable
    @textable_type ||= TextableDescriptor.new()
  end

  # Produces _sim suffix
  def self.project_facetable
    @project_facet_type ||= ProjectFacetDescriptor.new(:string, :indexed, :multivalued)
  end

  # Produces _sim suffix and a value-mapping converter
  def self.marc_code_facetable
    @marc_code_facet_type ||= MarcCodeFacetDescriptor.new(:string, :indexed, :multivalued)
  end

  # Produces _ssm suffix and a value-mapping converter
  def self.marc_code_displayable
    @marc_code_type ||= MarcCodeDisplayDescriptor.new(:string, :stored, :indexed, :multivalued)
  end

  # Produces all_text_timv fieldname and a value-mapping converter
  def self.marc_code_textable
    @marc_code_map_text_type ||= MarcCodeTextableDescriptor.new(:text, :indexed, :multivalued)
  end

  def self.load_value_maps(config_path=nil)
    if config_path.nil?
      if defined?(Rails.root) && !Rails.root.nil?
        config_path = File.join(Rails.root, "config", "solr_value_maps.yml")
      end
      # Default to using the config file within the gem
      if !File.exist?(config_path.to_s)
        logger.warn("ValueMapper: no field value maps at #{config_path}")
        config_path = File.join(File.dirname(__FILE__), "..", "..", "..", "config", "solr_value_maps.yml")
      end
      if !File.exist?(config_path.to_s)
        logger.warn("ValueMapper: no field value maps at #{File.expand_path(config_path)}")
        return {}
      end
    end
    logger.info("ValueMapper: loading field value maps from #{File.expand_path(config_path)}")
    YAML::load(File.open(config_path))
  end

  def self.value_maps
    @@value_maps ||= load_value_maps
  end

  def self.date_sortable_converter
    lambda do |type|
      lambda do |val| 
        begin
          d = val.length < 11 ? Date.new(*(val.split('-').collect {|s| s.to_i})) : Date.parse(val)
          iso8601_date(d)
        rescue ArgumentError
          nil 
        end
      end
    end
  end

  class TextableDescriptor < Solrizer::Descriptor 
    def name_and_converter(field_name, field_type)
      ['all_text_timv']
    end
  end

  class ProjectFacetDescriptor < Solrizer::Descriptor
    def converter(field_type)
      map = Solrizer::DefaultDescriptors.value_maps[:project_to_facet] || {}
      lambda {|value| (map.has_key? value) ? map[value] : value}
    end 
  end

  class MarcCodeFacetDescriptor < Solrizer::Descriptor
    def converter(field_type)
      map = Solrizer::DefaultDescriptors.value_maps[:marc_to_facet] || {}
      lambda {|value| (map.has_key? value) ? map[value] : value}
    end 
  end

  class MarcCodeDisplayDescriptor < Solrizer::Descriptor
    def converter(field_type)
      map = Solrizer::DefaultDescriptors.value_maps[:marc_to_display] || {}
      lambda {|value| (map.has_key? value) ? map[value] : value}
    end 
  end

  class MarcCodeTextableDescriptor < Solrizer::Descriptor
    def name_and_converter(field_name, field_type)
      ['all_text_timv', converter(field_type)]
    end
    def converter(field_type)
      fmap = Solrizer::DefaultDescriptors.value_maps[:marc_to_facet] || {}
      dmap = Solrizer::DefaultDescriptors.value_maps[:marc_to_display] || {}
      lambda do |value|
        r = (fmap.has_key? value) ? [fmap[value]] : []
        r << dmap[value] if (dmap.has_key? value)
        r.join(' ')
      end
    end
  end
  class MarcCodeDisplayTextableDescriptor < MarcCodeDisplayDescriptor
    def name_and_converter(field_name, field_type)
      puts "MarcCodeDisplayTextableDescriptor"
      ['all_text_timv', converter(field_type)]
    end
  end
end