module Cul
  module Hydra
    module Solrizer
      autoload :Extractor, "cul_hydra/solrizer/extractor"
      autoload :TerminologyBasedSolrizer, "cul_hydra/solrizer/terminology_based_solrizer"
      autoload :ValueMapper, "cul_hydra/solrizer/value_mapper"
      autoload :ModsFieldable, "cul_hydra/solrizer/mods_fieldable"
      autoload :AccessControlMetadataFields, "cul_hydra/solrizer/access_control_metadata_fields"
    end
  end
end