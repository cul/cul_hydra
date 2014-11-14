module NFO
  module Common
    extend ActiveSupport::Concern
    included do
      property :belongsToContainer, predicate: RDF::NFO[:"#belongsToContainer"], multivalue: false do |ix|
        ix.as :stored_sortable
      end
    end

    def to_solr(solr_doc={})
      solr_doc = super(solr_doc)
      if solr_doc['']
      end
      solr_doc
    end
  end
end