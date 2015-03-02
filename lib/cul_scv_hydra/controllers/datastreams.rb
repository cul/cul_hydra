module Cul::Scv::Hydra::Controllers
  module Datastreams
    extend ActiveSupport::Concern
    included do
      include Cul::Hydra::Controllers::Datastreams
    end
  end
end
