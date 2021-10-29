module Cul::Hydra::ApplicationIdBehavior
  extend ActiveSupport::Concern

  def find_for_params(path,solr_params)
    res = blacklight_config.repository.send_and_receive(path, {key=>solr_params.to_hash, method:blacklight_config.http_method})
    Blacklight::SolrResponse.new(res, solr_params, blacklight_config: blacklight_config)
  end

  def get_solr_response_for_app_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    id = id.clone
    id.sub!(/apt\:\/columbia/,'apt://columbia') # TOTAL HACK
    id.gsub!(':','\:')
    id.gsub!('/','\/')
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    p[:fq] = "identifier_ssim:#{(id)}"
    p[:fl] ||= '*'
    #p[:qt] ||= blacklight_config.document_solr_request_handler
    repository = blacklight_config.repository_class.new(blacklight_config)
    solr_response = repository.search(p)
    raise Blacklight::Exceptions::RecordNotFound.new(id) if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end

  def get_solr_response_for_dc_id(id=nil, extra_controller_params={})
    id ||= params[:id]
    id = id.clone
    p = blacklight_config.default_document_solr_params.merge(extra_controller_params)
    id.sub!(/apt\:\/columbia/,'apt://columbia') # TOTAL HACK
    id.gsub!(':','\:')
    id.gsub!('/','\/')
    p[:fq] = "dc_identifier_ssim:#{(id)}"
    p[:fl] ||= '*'
    #p[:qt] ||= blacklight_config.document_solr_request_handler
    repository = blacklight_config.repository_class.new(blacklight_config)
    solr_response = repository.search(p)
    raise Blacklight::Exceptions::RecordNotFound.new(id) if solr_response.docs.empty?
    document = SolrDocument.new(solr_response.docs.first, solr_response)
    @response, @document = [solr_response, document]
  end
end