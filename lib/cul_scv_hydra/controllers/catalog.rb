require 'cul_scv_hydra/controllers/aggregator_controller_helper'
require 'cul_scv_hydra/controllers/helpers/active_fedora_helper_behavior'
module Cul::Scv::Hydra
module Catalog
  include Cul::Scv::Hydra::Controllers::AggregatorControllerHelper
  include Cul::Scv::Hydra::Controllers::Helpers::ActiveFedoraHelperBehavior
  before_filter :require_solr, :require_fedora, :only=>[:show, :edit, :index, :delete]
  before_filter :load_resources, :only=>[:show, :edit]
  def edit
    if session[:scripts].blank?
      session[:scripts] = params[:combined] == "true"
    end 
    show_without_customizations
    remove_unapi
    enforce_edit_permissions
  end
end
