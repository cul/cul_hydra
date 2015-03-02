module Cul::Scv::Hydra::Controllers
  module Catalog
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::Catalog
    end
  end
end
