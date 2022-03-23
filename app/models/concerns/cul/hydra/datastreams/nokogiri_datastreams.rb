module Cul
module Hydra
module Datastreams
  module NokogiriDatastreams
    include ::ActiveFedora::Datastreams::NokogiriDatastreams
    def self.included(mod)
      mod.extend(::ActiveFedora::Datastreams::NokogiriDatastreams::ClassMethods)
    end
    def ng_xml_will_change!
      mutations_from_database.force_change(:ng_xml)
    end
  end
end
end
end
