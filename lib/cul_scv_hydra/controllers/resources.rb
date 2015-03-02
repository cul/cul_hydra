module Cul::Scv::Hydra::Controllers
  module Resources
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::Resources
    end
  end
end
