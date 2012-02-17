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
  def create_and_save_resource_from_params
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
      params[:Filedata] = blob
      params[:Filename] = file_name
    end
    if params.has_key?(:Filedata)
      @resource = create_resource_from_params
      @resource.save
      @resource.refresh
      add_posted_blob_to_resource
      @resource.save
      associate_resource_with_container
      @resource.save
      @resource.update_index
      return @resource
    else
      render :text => "400 Bad Request", :status => 400
    end
  end

  def create_resource_from_params
    file_name = filename_from_params
    resource = Resource.new
    resource.datastreams["rightsMetadata"].content = Hydra::RightsMetadata.xml_template
    resource.label = file_name
    resource.datastreams["DC"].update_values([:source]=>[file_name])
    resource
  end
  
  # Puts the contents of params[:Filedata] (posted blob) into a datastream within the given @resource
  # Sets resource label and title to filename if they're empty
  #
  # @param [Resource] the Resource to add the blob to
  # @return [Resource] the Resource  
  def add_posted_blob_to_resource(resource=@resource)
    file_name = filename_from_params
    _mime = mime_type(file_name)
    resource.add_content_blob(posted_file, :file_name=>file_name, :mime_type=>_mime)
  end
  
  # Associate the new file resource with its container
  def associate_resource_with_container(resource=nil, container_id=nil)
    if container_id.nil?
      container_id = params[:container_id]
    end
    if resource.nil?
      resource = @resource
    end
    resource.containers_append(container_id)
    #resource.add_relationship(:cul_member_of, container_id)
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
  def apply_posted_file_metadata         
    @metadata_update_response = update_document(@resource, @sanitized_params)
  end
  
  
  # The posted File 
  # @return [File] the posted file.  Defaults to nil if no file was posted.
  def posted_file
    params[:Filedata]
  end
  
  # A best-guess filename based on POST params
  # If Filename was submitted, it uses that.  Otherwise, it calls +original_filename+ on the posted file
  def filename_from_params
    if !params[:Filename].nil?
      file_name = params[:Filename]      
    else
      file_name = posted_file.original_filename
      params[:Filename] = file_name
    end
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
