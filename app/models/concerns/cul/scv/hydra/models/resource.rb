module Cul::Scv::Hydra::Models::Resource
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Models::Resource
  end
end
