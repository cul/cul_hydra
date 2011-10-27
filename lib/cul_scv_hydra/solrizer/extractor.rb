module Cul::Scv::Hydra::Solrizer
class Extractor < ::Solrizer::Extractor
  # Insert +field_value+ for +field_name+ into +solr_doc+
  # Handles inserting new values into a Hash while ensuring that you don't destroy or overwrite any existing values in the hash.
  # Ensures that field values are always appended to arrays within the values hash. 
  # Ensures that values are run through format_node_value
  # Also ensures that values are unique if specified
  # @param [Hash] solr_doc
  # @param [String] field_name
  # @param [String] field_value
  # @param [boolean] unique
  def self.insert_solr_field_value(solr_doc, field_name, field_value, unique=false)
    formatted_value = self.format_node_value(field_value)
    if solr_doc.has_key?(field_name)
      solr_doc[field_name] << formatted_value unless (unique and solr_doc[field_name].include? formatted_value)
    else
      solr_doc.merge!( {field_name => [formatted_value]} ) 
    end
    return solr_doc
  end

  # Instance Methods
  def insert_solr_field_value(solr_doc, field_name, field_value, unique=false)
    Cul::Scv::Hydra::Solrizer::Extractor.insert_solr_field_value(solr_doc, field_name, field_value, unique)
  end
end
end
