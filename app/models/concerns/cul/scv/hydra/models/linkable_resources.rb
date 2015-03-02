module Cul::Scv::Hydra::Models::LinkableResources
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Models::LinkableResources
  end
end
