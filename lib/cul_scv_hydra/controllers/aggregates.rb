require 'cul_scv_hydra/controllers/aggregator_controller_helper'
require 'cul_scv_hydra/controllers/helpers/resources_helper_behavior'
module Cul::Scv::Hydra::Controllers
module Aggregates
  extend ActiveSupport::Concern
  include Hydra::AssetsControllerHelper
  include Cul::Scv::Hydra::Controllers::AggregatorControllerHelper
  include Cul::Scv::Hydra::Controllers::Helpers::ResourcesHelperBehavior  
  include Hydra::RepositoryController  
  include MediaShelf::ActiveFedoraHelper
  include Blacklight::SolrHelper
  included do
    before_filter :require_solr, :only=>[:index, :create, :show, :destroy]
    before_filter :load_resources, :only=>[:index]
    prepend_before_filter :sanitize_update_params
  end

  def index

    if params[:layout] == "false"
      layout = false
    end
    container_uri = "info:fedora/#{params[:asset_id]}"
    escaped_uri = container_uri.gsub(/(:)/, '\\:')
    extra_controller_params =  {:q=>"cul_member_of_s:#{escaped_uri}"}
    @response, @document_list = get_search_results( extra_controller_params )
      
      # Including this line so permissions tests can be run against the container
    @container_response, @document = get_solr_response_for_doc_id(params[:asset_id])
      
    render :action=>params[:action], :layout=>layout
  end

  def load_aggregate
    if params.has_key? :aggregate_id
      af_base = ActiveFedora::Base.load_instance(params[:aggregate_id])
    else
      af_base = ActiveFedora::Base.load_instance(params[:id])
    end
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    if the_model.nil? or the_model == ActiveFedora::Base
      the_model = DcDocument
    end

    @resource = the_model.load_instance(af_base.pid)
  end
  
  # Creates and Saves a Parent - Child relationship in the Child's RELS-EXT
  # If container_id is provided:
  # * the File Asset will use RELS-EXT to assert that it's a part of the specified container
  # * the method will redirect to the container object's edit view after saving
  def create
    if params.has_key?(:aggregate_id)
      @resource = load_aggregate
      logger.debug @resource.class
      logger.debug @resource.datastreams["RELS-EXT"].content
      logger.debug @resource.to_rels_ext(@resource.pid)
      if !params[:asset_id].nil?
        associate_resource_with_container(@resource, params[:asset_id])
        @resource.save
        flash[:notice] = "Aggregated #{@resource.pid} under #{params[:asset_id]}."
      else
        flash[:notice] = "You must specify a container for the aggregate."
      end
    else
      flash[:notice] = "You must specify a resource to aggregate."
    end
    
    if !params[:asset_id].nil?
      redirect_params = {:controller=>"aggregates", :id=>params[:asset_id], :action=>:index}
    end
    
    redirect_params ||= {:action=>:index}
    
    redirect_to redirect_params
  end
  
  # Common destroy method for all AssetsControllers 
  def destroy
    @resource = load_aggregate
    remove_resource_from_container(@resource, params[:asset_id])
    @resource.save

    flash[:notice] = "Deleted #{params[:id]} from #{params[:asset_id]}."
    if !params[:asset_id].nil?
      redirect_params = {:controller=>"aggregates", :id=>params[:asset_id], :action=>:index}
    end
    
    redirect_params ||= {:action=>:index}
    
    redirect_to redirect_params
  end
end
end
