module NIE
  module InformationElement
    extend ActiveSupport::Concern
    included do
      property :isPartOf, predicate: RDF::NIE[:"#isPartOf"], multivalue: true do |ix|
        ix.as :symbol
      end
    end
  end
end