require 'cul_hydra/controllers/aggregator_controller_helper'
require 'cul_hydra/controllers/helpers/active_fedora_helper_behavior'
module Cul::Hydra::Controllers
module Catalog
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Controllers::AggregatorControllerHelper
    include Cul::Hydra::Controllers::Helpers::ActiveFedoraHelperBehavior
    before_filter :load_resources, :only=>[:show, :edit]
  end
end
end