module Cul::Scv::Hydra::ActiveFedora::Model
module Resource
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
    if self.respond_to? :has_relationship
      has_relationship "image_width", :image_width
      has_relationship "image_length", :image_length
      has_relationship "x_sampling", :x_sampling
      has_relationship "y_sampling", :y_sampling
      has_relationship "sampling_unit", :sampling_unit
      has_relationship "extent", :extent
      
      after_create :resource!      
    end
    if self.respond_to? :has_datastream
      has_datastream :name => "CONTENT", :type=>::ActiveFedora::Datastream
    end
  end
  
  def resource!
    add_relationship(:rdf_type, Cul::Scv::Hydra::ActiveFedora::RESOURCE_TYPE.to_s)
    @metadata_is_dirty = true
    update
  end

  def add_content_blob(blob, opts)
    file_name = opts[:file_name]
    mime = opts[:mime_type].nil? ? mime_type(file_name) : opts[:mime_type]
    add_file_datastream(blob, :label=>file_name, :mimeType=>mime, :dsid => 'CONTENT')
    set_title_and_label( file_name, :only_if_blank=>true )
    if IMAGE_MIME_TYPES.include? mime
      blob.rewind
      # retrieve Nokogiri of image property RDF
      image_prop_nodes = Cul::Image::Properties.identify(blob).nodeset
      relsext = datastreams['RELS-EXT']
      image_prop_nodes.each { |node|
        if node["resource"]
          is_literal = false
          object = RDF::URI.new(node["resource"])
        else
          is_literal = true
          object = RDF::Literal(node.text)
        end
        subject = RDF::URI(internal_uri)
        predicate = RDF::URI("#{node.namespace.href}#{node.name}")
        query = RDF::Query.new({ :subject => {predicate => :object}})
        relationships(predicate).dup.each { |stmt|
          relationships.delete(stmt)
        }
        add_relationship(predicate,object, is_literal)
        relationships_are_dirty=true
      }
      # add mimetype to DC:format values
      self.datastreams['DC'].update_values({[:format] => mime})
    end
    blob.rewind
  end

 private

  # Return the mimeType for a given file name
  # @param [String] file_name The filename to use to get the mimeType
  # @return [String] mimeType for filename passed in. Default: application/octet-stream if mimeType cannot be determined
  def mime_type file_name
    mime_types = MIME::Types.of(file_name)
    mime_type = mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type
  end
end
end
