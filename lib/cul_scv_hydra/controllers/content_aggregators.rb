module Cul::Scv::Hydra::Controllers
  module ContentAggregators
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::ContentAggregators
    end
  end
end
