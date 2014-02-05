module Cul
  module Scv
    module Hydra
      module Solrizer
      	autoload :Extractor, "cul_scv_hydra/solrizer/extractor"
      	autoload :TerminologyBasedSolrizer, "cul_scv_hydra/solrizer/terminology_based_solrizer"
      	autoload :ValueMapper, "cul_scv_hydra/solrizer/value_mapper"
      	autoload :ScvModsFieldable, "cul_scv_hydra/solrizer/scv_mods_fieldable"
      end
    end
  end
end
require "cul_scv_hydra/solrizer/field_mapper"