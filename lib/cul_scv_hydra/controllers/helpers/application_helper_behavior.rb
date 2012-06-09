# Methods added to this helper will be available to all templates in the application.
module Cul::Scv::Hydra::Controllers::Helpers
  module ApplicationHelperBehavior
    def load_dc_document_from_solr(doc)
      pid = doc[:id] ? doc[:id] : doc[:id.to_s]
      result = pid ? DcDocument.load_instance_from_solr(pid,doc) : nil
      result
    end
    def get_aggregate_count(doc)
      count = 0
      obj = load_dc_document_from_solr(doc)
      count += obj.parts.length unless obj.nil?
      count
    end
  end
end
