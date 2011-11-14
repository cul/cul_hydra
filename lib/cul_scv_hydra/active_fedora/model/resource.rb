module Cul
module Scv
module Hydra
module ActiveFedora
module Model
module Resource
module ModelMethods
# constants #
  IMAGE_MIME_TYPES = [
    'image/bmp',
    'image/gif',
    'image/jpeg',
    'image/png',
    'image/tiff'
  ]

  def self.included(mod)
    if mod.respond_to? :has_relationship
      mod.has_relationship "image_width", :image_width
      mod.has_relationship "image_length", :image_length
      mod.has_relationship "x_sampling", :x_sampling
      mod.has_relationship "y_sampling", :y_sampling
      mod.has_relationship "sampling_unit", :sampling_unit
      mod.has_relationship "extent", :extent
    end
    if mod.respond_to? :has_relationship
      mod.has_datastream :name => "CONTENT", :type=>::ActiveFedora::Datastream
    end
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
        ptr = query.execute(relationships)
        ptr.each { |stmt|
          if is_literal
            relationships.delete RDF::Statement.new(subject, predicate, RDF::Literal(stmt[:object]))
          else
            relationships.delete RDF::Statement.new(subject, predicate, RDF::URI(stmt[:object]))
          end
        }
        self.relationships.insert RDF::Statement.new(subject, predicate,object)
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
end
end
end
end
end
