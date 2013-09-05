require 'om'
module Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer
# copied from Solrizer::XML::TerminologyBasedSolrizer

  def self.included(klass)
    klass.send(:extend, ClassMethods)
  end
  
  # Module Methods
      
  module ClassMethods
    # Build a solr document from +doc+ based on its terminology
    # @param [OM::XML::Document] doc  
    # @param [Hash] solr_doc (optional) solr_doc (values hash) to populate
    def solrize(doc, solr_doc=Hash.new, field_mapper = nil)
      unless doc.class.terminology.nil?
        doc.class.terminology.terms.each_pair do |term_name,term|
          doc.solrize_term(term, solr_doc, field_mapper) unless term.is_root_term?
        end
      end

      return solr_doc
    end
  # Populate a solr document with solr fields corresponding to the given xml node
  # Field names are generated using settings from the term in the +doc+'s terminology corresponding to +term_pointer+
  # @param [Nokogiri::XML::Node] node to solrize
  # @param [OM::XML::Document] doc document the node came from
  # @param [Array] term_pointer Array pointing to the term that should be used for solrization settings
  # @param [Hash] (optional) solr_doc (values hash) to populate
    def solrize_node(node_value, doc, term_pointer, term, solr_doc = Hash.new, field_mapper = nil, opts = {})
      return solr_doc unless term.index_as && !term.index_as.empty?
      generic_field_name_base = OM::XML::Terminology.term_generic_name(*term_pointer)
      create_and_insert_terms(generic_field_name_base, node_value, term.index_as, solr_doc)
      
      if term_pointer.length > 1
        #hierarchical_field_name_base = OM::XML::Terminology.term_hierarchical_name(*term_pointer)
        #create_and_insert_terms(hierarchical_field_name_base, node_value, term.index_as, solr_doc)
      end
      if term.variant_of and term.variant_of[:field_base]
        #create_and_insert_terms(term.variant_of[:field_base], node_value, term.index_as, solr_doc)
        create_and_insert_terms(term.variant_of[:field_base], node_value, term.index_as, solr_doc)
      end
      solr_doc
    end

  end

end # module
