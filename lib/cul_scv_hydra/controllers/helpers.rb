module Cul::Scv::Hydra::Controllers
  module Helpers
    module ActiveFedoraHelperBehavior
      extend ActiveSupport::Concern
      included do
        include Cul::Hydra::Controllers::ActiveFedoraHelperBehavior
      end
    end
    end
    module ApplicationHelperBehavior
      extend ActiveSupport::Concern
      included do
        include Cul::Hydra::Controllers::ApplicationHelperBehavior
      end
    end
    module DcMetadataHelperBehavior
      extend ActiveSupport::Concern
      included do
        include Cul::Hydra::Controllers::DcMetadataHelperBehavior
      end
    end
    module HydraAssetsHelperBehavior
      extend ActiveSupport::Concern
      included do
        include Cul::Hydra::Controllers::HydraAssetsHelperBehavior
      end
    end
    module HydraAutocompleteHelperBehavior
      extend ActiveSupport::Concern
      included do
        include Cul::Hydra::Controllers::HydraAutocompleteHelperBehavior
      end
    end
    module HydraUploaderHelperBehavior
      extend ActiveSupport::Concern
      included do
        include Cul::Hydra::Controllers::HydraUploaderHelperBehavior
      end
    end
    module ResourcesHelperBehavior
      extend ActiveSupport::Concern
      included do
        include Cul::Hydra::Controllers::ResourcesHelperBehavior
      end
    end
  end
end