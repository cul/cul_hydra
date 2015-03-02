require 'om'
module Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Solrizer::TerminologyBasedSolrizer
  end
end
