require 'hydra'
require 'net/http'
require 'open-uri'
require 'tempfile'
require 'uri'
module Cul::Scv::Hydra::Controllers::Helpers
module ResourcesHelperBehavior
  IMAGE_MIME_TYPES = [
    'image/bmp',
    'image/gif',
    'image/jpeg',
    'image/png',
    'image/tiff'
  ]
  
  # Creates a Resource, adding the posted blob to the Resource's datastreams and saves the Resource
  #
  # @return [Resource] the Resource  
  def create_and_save_resources_from_params
    if params.has_key?(:Fileurl)
      # parse url for file name, default to index.html
      file_url = params[:Fileurl]
      file_url = URI.parse(file_url) unless file_url.nil?
      file_name = 'index.html'
      if file_url.scheme
        file_name = file_url.path[1...file_url.path.length]
      end
      # download resource; override file name with header value if present
      blob = Tempfile.new('temp')
      blob.binmode
      # download header? buffered writing?
      response = Net::HTTP.get_response(file_url)
      blob.write response.body
      if response['Content-Disposition']
        header = response['Content-Disposition']
        if header =~ /filename=\"?(\w+)\"?/
          file_name = $1
        end
      end
      # add filename and resource to params
      params[:Filedata] = ActionDispatch::Http::UploadedFile.new(:tempfile=>blob,:filename=>file_name,:type=>mime_type(file_name))
    end
    if params.has_key?(:Filedata)
      @resources = []
      params[:Filedata].each do |file|
        file.content_type = mime_type(file.original_filename) unless file.content_type
        @resource = create_resource_from_file(file)
        @resource.save
        @resources << @resource
        @resource.refresh
        add_posted_blob_to_resource(file, @resource)
        @resource.save
      end
    else
      render :text => "400 Bad Request", :status => 400
    end
    @resources
  end

  def create_resource_from_file(file)
    file_name = filename_for(file)
    resource = Resource.new
    resource.datastreams["rightsMetadata"].ng_xml = Hydra::RightsMetadata.xml_template
    resource.label = file_name
    resource.datastreams["DC"].update_values([:source]=>[file_name])
    resource
  end
  
  # Puts the contents of params[:Filedata] (posted blob) into a datastream within the given @resource
  # Sets resource label and title to filename if they're empty
  #
  # @param [Resource] the Resource to add the blob to
  # @return [Resource] the Resource  
  def add_posted_blob_to_resource(file, resource=@resource)
    resource.add_content_blob(file.tempfile, :file_name=>file.original_filename, :mime_type=>file.content_type)
  end
  
  # Associate the new file resource with its container
  def associate_resource_with_container(resource=@resource, container_id=nil)
    if container_id.nil?
      container_id = params[:container_id]
    end
    container_id = "info:fedora/#{container_id}" unless container_id =~ /info:fedora\/.+/
    resource.containers_append(container_id)
    resource.datastreams["RELS-EXT"].dirty = true
  end
  
  def remove_resource_from_container(resource=nil, container_id=nil)
    if container_id.nil?
      container_id = params[:container_id]
    end
    if resource.nil?
      resource = @resource
    end
    resource.containers_remove(container_id)
    #resource.remove_relationship(:cul_member_of, container_id)
    resource.datastreams["RELS-EXT"].dirty = true
  end
  
  # Apply any posted file metadata to the file asset
  def apply_posted_file_metadata(resource=@resource)         
    @metadata_update_response = update_document(resource, @sanitized_params)
  end
  
  
  # A best-guess filename
  # If Filename was submitted, it uses that.  Otherwise, it calls +original_filename+ on the posted file
  def filename_for(file)
    file.instance_variable_get(:@original_filename) || file.original_filename
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
