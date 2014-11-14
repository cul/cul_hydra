module SC
  class Sequence < ORE::Proxy
    include NIE::InformationElement
    property :viewingDirection, predicate: RDF::SC[:viewingDirection], multivalue: false do |ix|
      ix.as :stored_sortable
    end
    property :viewingHint, predicate: RDF::SC[:viewingHint], multivalue: false do |ix|
      ix.as :stored_sortable
    end
    property :canvases, predicate: RDF::SC[:hasCanvases], multivalue: true do |ix|
      ix.as :symbol
    end
    property :belongsToContainer, predicate: RDF::DC[:isPartOf], multivalue: false do |ix|
      ix.as :stored_sortable
    end
    def initialize(proxy_for_uri, context_uri, *args)
      super(proxy_for_uri, context_uri, *args)
      self.get_values(:type) << RDF::SC[:Sequence]
    end
  end
end