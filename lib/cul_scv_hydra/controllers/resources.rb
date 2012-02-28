module Cul::Scv::Hydra::Controllers
module Resources
  extend ActiveSupport::Concern
  include Hydra::AssetsControllerHelper
  include Cul::Scv::Hydra::Controllers::Helpers::ResourcesHelperBehavior
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  included do
    before_filter :require_solr, :only=>[:index, :create, :show, :destroy]
    prepend_before_filter :sanitize_update_params
  end

  def index
    if params[:layout] == "false"
      # action = "index_embedded"
      layout = false
    end
    if !params[:container_id].nil?
      container_uri = "info:fedora/#{params[:container_id]}"
      escaped_uri = container_uri.gsub(/(:)/, '\\:')
      extra_controller_params =  {:q=>"cul_member_of_s:#{escaped_uri}"}
      @response, @document_list = get_search_results( extra_controller_params )
      
      # Including this line so permissions tests can be run against the container
      @container_response, @document = get_solr_response_for_doc_id(params[:container_id])
      
      # Including these lines for backwards compatibility (until we can use Rails3 callbacks)
      @container =  ActiveFedora::Base.load_instance(params[:container_id])
      @solr_result = @container.file_objects(:response_format=>:solr)
    else
      # @solr_result = ActiveFedora::SolrService.instance.conn.query('has_model_field:info\:fedora/ldpd\:Resource', @search_params)
      @solr_result = Resource.find_by_solr(:all)
    end
    render :action=>params[:action], :layout=>layout
  end
  
  def new
    render :partial=>"new", :layout=>false
  end
  
  # Creates and Saves a File Asset to contain the the Uploaded file 
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    if params.has_key?(:Filedata) or params.has_key?(:Fileurl)
      flash[:notice] = process_files # "The file #{params[:Filename]} has been saved in <a href=\"#{asset_url(@resource.pid)}\">#{@resource.pid}</a>."
    else
      flash[:notice] = "You must specify a file to upload."
    end
    
    if !params[:container_id].nil?
      redirect_params = {:controller=>"catalog", :id=>params[:container_id], :action=>:edit}
    end
    
    redirect_params ||= {:action=>:index}
    
    redirect_to redirect_params
  end
  
  def process_files
    @resources = create_and_save_resources_from_params
    notice = []
    @resources.each do |resource|
      apply_depositor_metadata(resource)
      notice << "The file #{resource.label} has been saved in <a href=\"#{asset_url(resource.pid)}\">#{resource.pid}</a>."
      if !params[:container_id].nil?
        associate_resource_with_container(resource,params[:container_id])
      end
      ## Apply any posted file metadata
      unless params[:asset].nil?
        logger.debug("applying submitted file metadata: #{@sanitized_params.inspect}")
        apply_posted_file_metadata(resource)
      end
      resource.save
      logger.debug("Created #{resource.pid}.")
    end
  end
  # Common destroy method for all AssetsControllers 
  def destroy
    # The correct implementation, with garbage collection:
    # if params.has_key?(:container_id)
    #   container = ActiveFedora::Base.load_instance(params[:container_id]) 
    #   container.file_objects_remove(params[:id])
    #   FileAsset.garbage_collect(params[:id])
    # else
    
    # The dirty implementation (leaves relationship in container object, deletes regardless of whether the file object has other containers)
    ActiveFedora::Base.load_instance(params[:id]).delete 
    flash[:notice] = "Deleted #{params[:id]}."
    if !params[:container_id].nil?
      redirect_params = {:controller=>"catalog", :id=>params[:container_id], :action=>:edit}
    end
    
    redirect_params ||= {:action=>:index}
    
    redirect_to redirect_params
  end
  
  
  def show
    @file_asset = Resource.find(params[:id])
    if (@file_asset.nil?)
      logger.warn("No such resource: " + params[:id])
      flash[:notice]= "No such resource."
      redirect_to(:action => 'index', :q => nil , :f => nil)
    else
      # get array of parent (container) objects for this FileAsset
      @id_array = @file_asset.containers(:response_format => :id_array)
      @downloadable = false
      # A FileAsset is downloadable iff the user has read or higher access to a parent
      @id_array.each do |pid|
        @response, @document = get_solr_response_for_doc_id(pid)
        if reader?
          @downloadable = true
          break
        end
      end

      if @downloadable
        if @file_asset.datastreams_in_memory.include?("CONTENT")
          send_datastream @file_asset.datastreams_in_memory["CONTENT"]
        end
      else
        flash[:notice]= "You do not have sufficient access privileges to download this document, which has been marked private."
        redirect_to(:action => 'index', :q => nil , :f => nil)
      end
    end
  end
end
end
