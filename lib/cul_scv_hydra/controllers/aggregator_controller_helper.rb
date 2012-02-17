require 'active-fedora'
module Cul
module AggregatorControllerHelper
  def load_resources
    if params.has_key? :asset_id
      af_base = ActiveFedora::Base.load_instance(params[:asset_id])
    else
      af_base = ActiveFedora::Base.load_instance(params[:id])
    end
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil? or the_model == ActiveFedora::Base
      the_model = DcDocument
    end

    @document_fedora = af_base.adapt_to the_model
    @resources = @document_fedora.resources(:response_format=>:solr)
  end
end
end
