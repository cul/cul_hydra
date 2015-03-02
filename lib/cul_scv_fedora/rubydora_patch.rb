module Cul
  module Scv
    module Fedora
      module RubydoraPatch
        extend ActiveSupport::Concern
        included do
          include Cul::Hydra::Fedora::RubydoraPatch
        end
      end
    end
  end
end
