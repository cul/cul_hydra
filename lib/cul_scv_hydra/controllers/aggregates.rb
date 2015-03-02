module Cul::Scv::Hydra::Controllers
  module Aggregates
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::Aggregates
    end
  end
end
