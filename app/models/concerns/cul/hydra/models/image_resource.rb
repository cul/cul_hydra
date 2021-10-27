module Cul::Hydra::Models::ImageResource
  IMAGE_EXT = {"image/bmp" => 'bmp', "image/gif" => 'gif', "image/jpeg" => 'jpg', "image/png" => 'png', "image/tiff" => 'tif', "image/x-windows-bmp" => 'bmp', 'image/jp2' => 'jp2'}
  WIDTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_width))
  LENGTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_length))
  WIDTH_PREDICATE = ActiveFedora::Predicates.short_predicate("http://www.w3.org/2003/12/exif/ns#imageWidth").to_s
  LENGTH_PREDICATE = ActiveFedora::Predicates.short_predicate("http://www.w3.org/2003/12/exif/ns#imageLength").to_s
  EXTENT_PREDICATE = ActiveFedora::Predicates.short_predicate("http://purl.org/dc/terms/extent").to_s
  FORMAT_OF_PREDICATE = ActiveFedora::Predicates.short_predicate("http://purl.org/dc/terms/isFormatOf").to_s
  FORMAT_URI = RDF::URI("http://purl.org/dc/terms/format")

  EXIF_ORIENTATION_TO_DEGREES = {
    'top-left' => 0,
    'left-bottom' => 90,
    'bottom-right' => 180,
    'right-top' => 270
  }
  DEGREES_TO_EXIF_ORIENTATIONS = EXIF_ORIENTATION_TO_DEGREES.invert

  def long
    @long_side ||= max(width(), length())
  end

  def width
    @width ||= begin
      ds = datastreams["content"]
      width = 0
      unless ds.nil? or rels_int.relationships(ds,:exif_image_width).blank?
        width = rels_int.relationships(ds,:exif_image_width).first.object.to_s.to_i
      end
      width = relationships(:image_width).first.to_s.to_i if width == 0
      width
    end
  end

  def length
    @length ||= begin
      ds = datastreams["content"]
      length = 0
      unless ds.nil? or rels_int.relationships(ds,:exif_image_length).blank?
        length = rels_int.relationships(ds,:exif_image_length).first.object.to_s.to_i
      end
      length = relationships(:image_length).first.to_s.to_i if length == 0
      length
    end
  end

  # The number of rotational degrees required to display this image as upright
  def required_rotation_for_upright_display
    required_rotation_orientation_in_degrees = (360 - self.orientation) % 360
    return required_rotation_orientation_in_degrees
  end

  # Allowed degrees arg values: 0, 90, 180, 270
  def orientation=(degrees)
    degrees = degrees % 360
    raise "Invalid value for degrees.  Must be a right angle (0, 90, 180, etc.)" unless (degrees % 90 == 0)
    self.clear_relationship(:orientation)
    self.add_relationship(:orientation, DEGREES_TO_EXIF_ORIENTATIONS[degrees], true)
    return degrees # Hide RDF backing structure and make this look like a simple setter method
  end

  def orientation
    self.relationships(:orientation).present? ? EXIF_ORIENTATION_TO_DEGREES[self.relationships(:orientation).first.to_s] : 0
  end
end
