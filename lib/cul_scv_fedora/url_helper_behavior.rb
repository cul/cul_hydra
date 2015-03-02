module Cul
  module Scv
    module Fedora
      module UrlHelperBehavior
        extend ActiveSupport::Concern
        included do
          include Cul::Hydra::Fedora::UrlHelperBehavior
        end
      end
    end
  end
end