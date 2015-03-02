module Cul::Scv::Hydra::Resolver
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Resolver
  end
end