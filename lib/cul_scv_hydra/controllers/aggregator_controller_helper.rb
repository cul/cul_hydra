require 'active-fedora'
module Cul::Scv::Hydra::Controllers
module AggregatorControllerHelper
  def load_fedora_document
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
  end
  def load_resources
    @document_fedora ||= load_fedora_document
    if @document_fedora.is_a? Cul::Scv::Hydra::ActiveFedora::Model::Aggregator
      @resources = @document_fedora.resources
    else
      logger.debug "Only aggregators have parts!"
    end
    @resources
  end
end
end
