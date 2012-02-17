module Cul::Scv::Hydra::Controllers::Helpers
  module ActiveFedoraHelperBehavior
    def load_dc_document_from_solr(doc)
      pid = doc[:id] ? doc[:id] : doc[:id.to_s]
      result = pid ? Cul::Scv::Hydra::ActiveFedora::Model::DcDocument.load_instance_from_solr(pid,doc) : nil
      logger.debug "I swear I'm in your code" + result.to_s
      result
    end
  end
end
