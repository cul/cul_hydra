module Cul::Scv::Hydra::Models::Aggregator
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Models::Aggregator
  end
end
