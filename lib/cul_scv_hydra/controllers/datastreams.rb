require 'cul_scv_hydra/controllers/helpers/application_helper_behavior'
module Cul::Scv::Hydra::Controllers
  module Datastreams
  extend ActiveSupport::Concern
  include Cul::Scv::Hydra::Controllers::Helpers::ApplicationHelperBehavior
  include Hydra::AssetsControllerHelper
  include Hydra::AssetsControllerHelper
  include Hydra::FileAssetsHelper  
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
    unless params[:asset_id].nil?
      
      # Including this line so permissions tests can be run against the container
      @container_response, @document = get_solr_response_for_doc_id(params[:asset_id])
      
      # Including these lines for backwards compatibility (until we can use Rails3 callbacks)
      @container =  ActiveFedora::Base.load_instance(params[:asset_id])
      @ds = @container.datastreams(params[:id])
    else
      # What are we doing here without a containing object?
      raise "called DatastreamsController#index without containing object"
    end
    render :action=>params[:action], :layout=>layout
  end
  
  def new
    render :partial=>"new", :layout=>false
  end
  
  # Creates and Saves a Datastream to contain the the Uploaded file 
  def create
    if params[:asset_id].nil?
      raise "Cannot created a datastream without a containing object"
    else
      @container =  ActiveFedora::Base.load_instance(params[:asset_id])
    end

    if params[:id].nil?
      raise "Cannot created a datastream without a datastream id"
    end

    if params.has_key?(:Filedata)
      file_name = filename_from_params
      mime_type = params[:mime_type] || mime_type(file_name)
      @container.add_file_datastream(posted_file, :dsid=>params[:id], :label=>file_name, :mimeType=>mime_type, :size=>posted_file.size)
      @container.save
      # apply_depositor_metadata(@file_asset)
    
      flash[:notice] = "The file #{params[:Filename]} has been saved as #{params[:datastream_id]} in <a href=\"#{asset_url(@container.pid)}\">#{@container.pid}</a>."
            
      ## Apply any posted file metadata
      unless params[:asset].nil?
       # logger.debug("applying submitted file metadata: #{@sanitized_params.inspect}")
       # apply_file_metadata
      end
      # If redirect_params has not been set, use {:action=>:index}
      logger.debug "Created #{@container.pid}##{params[:datastream_id]}."
    elsif params.has_key?(:Source)
      file_name = filename_from_url(params[:Source])
      mime_type = params[:mime_type] || mime_type(file_name)
      ds_props = {:dsid=>params[:id], :label=>file_name, :mimeType=>mime_type, :dsLocation=>params[:Source]}
      @container.add_datastream(ActiveFedora::Datastream.new(ds_props))
      @container.save
    
      flash[:notice] = "#{params[:Source]} has been saved as #{params[:datastream_id]} in <a href=\"#{asset_url(@container.pid)}\">#{@container.pid}</a>."
    else
      flash[:notice] = "You must specify a file to upload or a source URL."
    end
    
    unless params[:container_id].nil?
      redirect_params = {:controller=>"catalog", :id=>params[:asset_id], :action=>:edit}
    end
    
    redirect_params ||= {:action=>:index}
    
    redirect_to redirect_params
  end
  
  # Datastream destroy method
  def destroy
    @container = ActiveFedora::Base.load_instance(params[:asset_id])
    @container.datastreams[params[:datastream_id]].delete
    render :text => "Deleted #{params[:datastream_id]} from #{params[:asset_id]}."
    # Does the index need to be updated on delete here?
    @container.save
  end
  
  def update
    self.create
  end
  
  def show
    @container = ActiveFedora::Base.find(params[:asset_id])
    if (@container.nil?)
      logger.warn("No such fedora object: " + params[:asset_id])
      flash[:notice]= "No such fedora object."
      redirect_to(:action => 'index', :q => nil , :f => nil)
      return
    else
      # get array of parent (container) objects for this FileAsset
      @downloadable = false
      # A FileAsset is downloadable iff the user has read or higher access to a parent
      @response, @document = get_solr_response_for_doc_id(params[:asset_id])
      if reader?
        @downloadable = true
      end

      if @downloadable
        if @container.datastreams_in_memory.include?(params[:id])
          ds = @container.datastreams_in_memory[params[:id]]
          opts = {:filename => ds.label}
          if params[:mime_type].nil?
            opts[:type] = ds.attributes["mimeType"]
          else
            opts[:type] = params[:mime_type]
          end
          if params[:disposition].nil?
            opts[:disposition] = "attachment"
          else
            opts[:disposition] = params[:disposition]
          end
          logger.debug opts.inspect
          send_data ds.content, opts
          return
        end
      else
        flash[:notice]= "You do not have sufficient access privileges to download this document, which has been marked private."
        redirect_to(:action => 'index', :q => nil , :f => nil)
        return
      end
    end
  end
end
end
