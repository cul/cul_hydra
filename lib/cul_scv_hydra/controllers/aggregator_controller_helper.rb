module Cul::Scv::Hydra::Controllers
  module AggregatorControllerHelper
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::AggregatorControllerHelper
    end
  end
end
