module Cul::Scv::Hydra::Thumbnails
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Thumbnails
  end
end