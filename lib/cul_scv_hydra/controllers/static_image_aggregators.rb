require 'cul_scv_hydra/controllers/helpers/resources_helper_behavior'
module Cul::Scv::Hydra::Controllers
  module StaticImageAggregators
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::StaticImageAggregators
    end
  end
end
