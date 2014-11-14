module SC
  class Canvas < ORE::Proxy
    include NIE::InformationElement
    property :belongsToContainer, predicate: RDF::DC[:isPartOf], multivalue: false do |ix|
      ix.as :stored_sortable
    end
    def initialize(proxy_for_uri, context_uri, *args)
      super(proxy_for_uri, context_uri, *args)
      self.get_values(:type) << RDF::SC[:Canvas]
    end
  end
end