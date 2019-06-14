module Cul
module Hydra
module Datastreams
class AccessControlMetadata < ::ActiveFedora::Datastream
  include ::ActiveFedora::Datastreams::NokogiriDatastreams
  include Cul::Hydra::Solrizer::AccessControlMetadataFields
end
end
end
end
