class BagAggregator < GenericAggregator
  rdf_types(RDF::Cul.Aggregator)
  rdf_types(RDF::PCDM.Collection)
  def route_as
    "collection"
  end

end
