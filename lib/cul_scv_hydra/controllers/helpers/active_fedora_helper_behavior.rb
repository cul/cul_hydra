module Cul::Scv::Hydra::Controllers::Helpers
  module ActiveFedoraHelperBehavior
    def load_dc_document_from_solr(doc)
      pid = doc[:id] ? doc[:id] : doc[:id.to_s]
      result = pid ? DcDocument.load_instance_from_solr(pid,doc) : nil
      result
    end
  end
end
