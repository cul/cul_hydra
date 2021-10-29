require 'blacklight'
require 'active-fedora'
module Cul::Hydra::Resolver
  extend ActiveSupport::Concern

  included do 
    # Whenever an action raises SolrHelper::RecordNotFound, this block gets executed.
    # Hint: the SolrHelper #get_solr_response_for_doc_id method raises this error,
    # which is used in the #show action here.
    self.rescue_from Blacklight::Exceptions::RecordNotFound, :with => :invalid_solr_id_error
    # When RSolr::RequestError is raised, the rsolr_request_error method is executed.
    # The index action will more than likely throw this one.
    # Example, when the standard query parser is used, and a user submits a "bad" query.
    self.rescue_from RSolr::Error::Http, :with => :rsolr_request_error
  end

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    solr_params = blacklight_config.default_document_solr_params.merge!(extra_controller_params)
    solr_params[:fq] = "identifier_ssim:#{(id)}"
    solr_response = find((blacklight_config.document_solr_request_handler || blacklight_config.qt), solr_params)
    raise Blacklight::Exceptions::RecordNotFound.new if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def get
    get_solr_response_for_app_id
    action = params.delete(:action)
    action.sub!(/s$/,'')
    method_name = action + '_url'
    url = send method_name.to_sym, @document[:id]
    redirect_to url
  end

  # when solr (RSolr) throws an error (RSolr::RequestError), this method is executed.
  def rsolr_request_error(exception)
    if Rails.env == "development"
      raise exception # Rails own code will catch and give usual Rails error page with stack trace
    else
      flash_notice = I18n.t('blacklight.search.errors.request_error')
      # Set the notice flag if the flash[:notice] is already set to the error that we are setting.
      # This is intended to stop the redirect loop error
      notice = flash[:notice] if flash[:notice] == flash_notice
      logger.error exception
      unless notice
        flash[:notice] = flash_notice
        redirect_to root_path, :status => 500
      else
        render :file => "#{Rails.root}/public/500.html", :status => 500
      end
    end
  end

  # when a request for /resolve/:action/BAD_SOLR_ID is made, this method is executed...
  def invalid_solr_id_error
    id = params.delete(:id)
    flash[:notice] = I18n.t('blacklight.search.errors.invalid_solr_id') + " (#{id})"
  	redirect_to(root_path)
  end

  def blacklight_solr
    @solr ||=  Blacklight.default_index
  end
end