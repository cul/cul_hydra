require 'solrizer'
module Solrizer::DefaultDescriptors
  def self.date_sortable
    @date_sortable ||= Solrizer::Descriptor.new(:date, :stored, :indexed, converter: date_sortable_converter)
  end

  # Produces the field name 'all_text_teim'
  def self.textable
    @textable_type ||= TextableDescriptor.new(:text_en, :indexed, :multivalued)
  end

  # Produces _sim suffix
  def self.project_facetable
    @project_facet_type ||= ProjectFacetDescriptor.new(:string, :indexed, :multivalued)
  end

  def self.project_textable
    @project_textable_type ||= ProjectTextableDescriptor.new(:text_en, :indexed, :multivalued)
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
    @marc_code_map_text_type ||= MarcCodeTextableDescriptor.new(:text_en, :indexed, :multivalued)
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

  module Normal
    SHORT_REPO = "ldpd.short.repo."
    SHORT_PROJ = "ldpd.short.project."
    LONG_REPO  = "ldpd.long.repo."
    def normal(value)
      normal!(value.clone)
    end
    def normal!(value)
      value.gsub!(/\s+/,' ')
      value.strip!
      value
    end
    def translate_with_default(prefix, value)
      begin
        return I18n.t(prefix + value, default: value)
      rescue
        return value
      end
    end
  end

  class TextableDescriptor < Solrizer::Descriptor
    include Normal
    def name_and_converter(field_name, args=nil)
      super('all_text', args)
    end
    def converter(field_type)
      lambda {|value| normal(value)}
    end
  end

  class ProjectTextableDescriptor < Solrizer::Descriptor
    include Normal
    def name_and_converter(field_name, args=nil)
      super('all_text', args)
    end
    def converter(field_type)
      lambda do |value|
        if value.is_a? String
          translate_with_default(SHORT_PROJ, normal!(value))
        else
          raise "unexpected project_textable #{value.inspect}"
          value
        end
      end
    end
  end

  class ProjectFacetDescriptor < Solrizer::Descriptor
    include Normal
    def converter(field_type)
      lambda {|value| translate_with_default(SHORT_PROJ, normal!(value))}
    end
  end

  class MarcCodeFacetDescriptor < Solrizer::Descriptor
    include Normal
    def converter(field_type)
      lambda {|value| translate_with_default(SHORT_REPO, normal!(value))}
    end
  end

  class MarcCodeDisplayDescriptor < Solrizer::Descriptor
    include Normal
    def converter(field_type)
      lambda {|value| translate_with_default(LONG_REPO, normal!(value))}
    end
  end

  class MarcCodeTextableDescriptor < Solrizer::Descriptor
    include Normal
    def name_and_converter(field_name, args=nil)
      super('all_text', args)
    end
    def converter(field_type)
      lambda do |value|
        if value.is_a? String
          normal!(value)
          r = [translate_with_default(SHORT_REPO, value)]
          r << translate_with_default(LONG_REPO, value)
          r.uniq!
          r.join(' ')
        else
          value
        end
      end
    end
  end
end
