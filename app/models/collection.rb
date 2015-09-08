class Collection < GenericAggregator
  include Pcdm::Models
  include Pcdm::Models::Collections
  rdf_types(RDF::CUL.Aggregator)
  rdf_types(RDF::PCDM.Collection)

end