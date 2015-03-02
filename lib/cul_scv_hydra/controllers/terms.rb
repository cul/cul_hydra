module Cul::Scv::Hydra::Controllers
  module Terms
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::Terms
    end
  end
end
