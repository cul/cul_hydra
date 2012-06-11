require 'cul_scv_hydra/controllers/aggregator_controller_helper'
require 'cul_scv_hydra/controllers/helpers/active_fedora_helper_behavior'
module Cul::Scv::Hydra::Controllers
module Catalog
  extend ActiveSupport::Concern
  included do
    include Cul::Scv::Hydra::Controllers::AggregatorControllerHelper
    include Cul::Scv::Hydra::Controllers::Helpers::ActiveFedoraHelperBehavior
    before_filter :load_resources, :only=>[:show, :edit]
  end
end
end
