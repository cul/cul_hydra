require 'solrizer'
module Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer
# copied from Solrizer::XML::TerminologyBasedSolrizer
  def self.default_field_mapper
    @@default_field_mapper ||= Cul::Scv::Hydra::Solrizer::FieldMapper.default
  end

  def self.default_extractor
    @@default_extractor ||= Cul::Scv::Hydra::Solrizer::Extractor.new
  end

  def self.default_value_mapper
    @@value_mapper ||= Cul::Scv::Hydra::Solrizer::ValueMapper.new
  end

  
  # Module Methods
  
  # Build a solr document from +doc+ based on its terminology
  # @param [OM::XML::Document] doc  
  # @param [Hash] (optional) solr_doc (values hash) to populate
  def self.solrize(doc, solr_doc=Hash.new, field_mapper = nil)
    unless doc.class.terminology.nil?
      doc.class.terminology.terms.each_pair do |term_name,term|
        doc.solrize_term(term, solr_doc, field_mapper)
        # self.solrize_by_term(accessor_name, accessor_info, :solr_doc=>solr_doc)
      end
    end

    return solr_doc
  end
  
  # Populate a solr document with fields based on nodes in +xml+ corresponding to the 
  # term identified by +term_pointer+ within +terminology+
  # @param [OM::XML::Document] doc xml document to extract values from
  # @param [OM::XML::Term] term corresponding to desired xml values
  # @param [Hash] (optional) solr_doc (values hash) to populate
  # @param [Solrizer::FieldMapper] (optional) object that maps a term and its index options to solr field names
  def self.solrize_term(doc, term, solr_doc = Hash.new, field_mapper = nil, opts={})
    terminology = doc.class.terminology
    parents = opts.fetch(:parents, [])

    term_pointer = parents+[term.name]
    nodeset = doc.find_by_terms(*term_pointer)
    nodeset.each do |node|
      # create solr fields
      
      doc.solrize_node(node, term_pointer, term, solr_doc, field_mapper)
      unless term.kind_of? OM::XML::NamedTermProxy
        term.children.each_pair do |child_term_name, child_term|
          doc.solrize_term(child_term, solr_doc, field_mapper, opts={:parents=>parents+[{term.name=>nodeset.index(node)}]})
        end
      end
    end
    solr_doc
  end
  
  # Populate a solr document with solr fields corresponding to the given xml node
  # Field names are generated using settings from the term in the +doc+'s terminology corresponding to +term_pointer+
  # @param [Nokogiri::XML::Node] node to solrize
  # @param [OM::XML::Document] doc document the node came from
  # @param [Array] term_pointer Array pointing to the term that should be used for solrization settings
  # @param [Hash] (optional) solr_doc (values hash) to populate
  def self.solrize_node(node, doc, term_pointer, term, solr_doc = Hash.new, field_mapper = nil, opts = {})
    terminology = doc.class.terminology
    # term = terminology.retrieve_term(*term_pointer)
    if term.path.kind_of?(Hash) && term.path.has_key?(:attribute)
      node_value = node.value
    else
      node_value = node.text
    end
    generic_field_name_base = OM::XML::Terminology.term_generic_name(*term_pointer)
    
    self.insert_field_value(solr_doc, term, generic_field_name_base, node_value, term.data_type, term.index_as, field_mapper)
    
    if term_pointer.length > 1
      hierarchical_field_name_base = OM::XML::Terminology.term_hierarchical_name(*term_pointer)
      self.insert_field_value(solr_doc, term, hierarchical_field_name_base, node_value, term.data_type, term.index_as, field_mapper)
    end
    if term.variant_of and term.variant_of[:field_base]
      self.insert_field_value(solr_doc, term, term.variant_of[:field_base], node_value, term.data_type, term.index_as, field_mapper, true)
    end
    solr_doc
  end

  def self.insert_field_value(solr_doc, term, field_base_name, field_value, data_type, index_as, field_mapper=nil , unique=false)
    field_mapper = self.default_field_mapper if field_mapper.nil?
    field_mapper.solr_names_and_values(field_base_name, field_value, data_type, index_as).each { |field_name, field_value|
        unless field_value.join("").strip.empty?
          if term.variant_of and term.variant_of[:map]
            field_value = default_value_mapper.solr_value(term.variant_of[:map], field_value)
          end
          self.default_extractor.insert_solr_field_value(solr_doc, field_name, field_value, (unique || (field_name == 'text')))
        end
    }
  end
# Instance Methods
  
  attr_accessor :field_mapper
  
  def to_solr(solr_doc = Hash.new, field_mapper = self.field_mapper) # :nodoc:
    ::Solrizer::XML::TerminologyBasedSolrizer.solrize(self, solr_doc, field_mapper)
  end
  
  def solrize_term(term, solr_doc = Hash.new, field_mapper = self.field_mapper, opts={})
    Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer.solrize_term(self, term, solr_doc, field_mapper, opts)    
  end

  def solrize_node(node, term_pointer, term, solr_doc = Hash.new, field_mapper = self.field_mapper, opts={})
    Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer.solrize_node(node, self, term_pointer, term, solr_doc, field_mapper, opts)
  end
end # module
