module Cul::Hydra::Controllers::Helpers
  module DcMetadataHelperBehavior
    def dcmi_types
      ['', 'Collection', 'Dataset', 'Event', 'Image', 'InteractiveResource',
       'MovingImage', 'PhysicalObject', 'Service', 'Software', 'Sound',
       'StillImage', 'Text']
    end
  end
end
