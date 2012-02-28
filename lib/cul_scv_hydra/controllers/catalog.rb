require 'cul_scv_hydra/controllers/aggregator_controller_helper'
require 'cul_scv_hydra/controllers/helpers/active_fedora_helper_behavior'
module Cul::Scv::Hydra::Controllers
module Catalog
  extend ActiveSupport::Concern
  include Cul::Scv::Hydra::Controllers::AggregatorControllerHelper
  include Cul::Scv::Hydra::Controllers::Helpers::ActiveFedoraHelperBehavior
  included do
    before_filter :require_solr, :only=>[:show, :edit, :index, :delete]
    before_filter :load_resources, :only=>[:show, :edit]
  end
end
end
