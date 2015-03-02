module Cul::Scv::Hydra::AccessControlsEnforcement
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::AccessControlsEnforcement
  end
end
