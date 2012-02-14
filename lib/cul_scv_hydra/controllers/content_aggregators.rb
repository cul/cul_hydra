require 'cul'
module Cul::Scv:Hydra::Controllers
 module ContentAggregators
  extend ActiveSupport::Concern
  include Hydra::AssetsControllerHelper
  include Cul::ResourcesHelper  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  included do
    self.before_filter :require_fedora
    self.before_filter :require_solr, :only=>[:index, :new, :create, :edit, :show, :destroy]
    self.prepend_before_filter :sanitize_update_params
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
    @asset = ContentAggregator.new
    apply_depositor_metadata(@asset)
    set_collection_type(@asset, params[:content_type])
    if !params[:container_id].nil?
      associate_resource_with_container(@asset, params[:container_id])
    end
    @asset.save
    msg = "Created a Content Aggregator with pid #{@asset.pid}. Now it's ready to be edited."
    flash[:notice]= msg
  
    session[:scripts] = params[:combined] == "true"
    redirect_to url_for(:action=>"edit", :id=>@asset.pid, :new_asset=>true, :controller=>'catalog')

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
    render :text => "Deleted #{params[:id]} from #{params[:container_id]}."
  end
  
  
  def show
    @image_agg = ContentAggregator.find(params[:id])
    if (@image_agg.nil?)
      logger.warn("No such object: " + params[:id])
      flash[:notice]= "No such object."
      redirect_to(:action => 'index', :q => nil , :f => nil)
    else
      @id_array = @image_agg.containers(:response_format => :id_array)
    end
    render :action=>params[:action], :layout=>(params[:layout]=="false")
  end
end
end
