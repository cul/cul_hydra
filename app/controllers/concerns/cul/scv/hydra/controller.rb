module Cul::Scv::Hydra::Controller
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Controller
  end
end