class Collection < GenericAggregator
  include Pcdm::Models
  rdf_types(RDF::CUL.Aggregator)
  rdf_types(RDF::PCDM.Collection)

end