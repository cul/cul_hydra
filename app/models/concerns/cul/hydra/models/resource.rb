module Cul::Hydra::Models::Resource
    extend ActiveSupport::Concern
# constants #
  IMAGE_MIME_TYPES = [
    'image/bmp',
    'image/gif',
    'image/jpeg',
    'image/png',
    'image/tiff'
  ]

  included do
    if self.is_a? ::ActiveFedora::SemanticNode
      props = {
        "image_width" => :image_width,
        "image_length" => :image_length,
        "x_sampling" => :x_sampling,
        "y_sampling" => :y_sampling,
        "sampling_unit" => :sampling_unit,
        "extent" => :extent,
      }
      props.each { |x, y|
        class_eval %Q{
          def #{x}
            return relationships[:#{y.to_s}]
        }
      }

      after_create :resource!
    end
  end

  def resource!
    add_relationship(:rdf_type, RDF::Cul.Resource.to_s)
    add_relationship(:rdf_type, RDF::PCDM.Object.to_s)
    @metadata_is_dirty = true
    update
  end
end