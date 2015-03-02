module Cul::Scv::Hydra::Controllers
  module Suggestions
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::Suggestions
    end
  end
end
