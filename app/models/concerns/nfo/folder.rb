module NFO
  class Folder < ORE::Proxy
    include NIE::InformationElement
    include NFO::Common
    def initialize(proxy_for_uri, context_uri, *args)
      super(proxy_for_uri, context_uri, *args)
      self.get_values(:type) << RDF::NFO[:"#Folder"]
    end
  end
end