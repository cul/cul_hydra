require "active-fedora"
require "active_fedora_finders"
class GenericAggregator < ::ActiveFedora::Base
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include Cul::Hydra::Models::Common
  include Cul::Hydra::Models::Aggregator

  has_many :parts, :property => :cul_member_of, :class_name=>'ActiveFedora::Base'

  def route_as
    "multipartitem"
  end

  def index_type_label
    riquery = Cul::Hydra::Models::MEMBER_ITQL.gsub(/%PID%/, self.pid)
    begin
      docs = Cul::Hydra::Fedora.repository.find_by_itql riquery, limit: 2, format: 'count/json'
      docs = JSON.parse(docs)['results']
      size = docs.first && docs.first['count'] && docs.first['count'].to_i
    rescue Exception=>e
      Rails.logger.warn("#{self.class.name} failed to find children with TQL: #{e.message}")
    end
    size ||= self.parts(response_format: :solr, limit: 2).size
    type_label_for(size)
  end

  def type_label_for(size=nil)
    if size == 0
      return "EMPTY"
    elsif size == 1
      return "SINGLE PART"
    else
      return "MULTIPART"
    end
  end

  # set the index type label and any RI-based fields
  # overridde
  def set_size_labels(solr_doc={})
    count = Cul::Hydra::RisearchMembers.get_direct_member_count(pid)
    solr_doc["index_type_label_ssi"] = [type_label_for(count)]
    solr_doc["cul_number_of_members_isi"] = count
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super(solr_doc, opts)
    solr_doc
  end

  def proxies
    datastreams['structMetadata'] ? datastreams['structMetadata'].proxies : []
  end
  def update_index
    super
    if has_struct_metadata?()
      conn = ActiveFedora::SolrService.instance.conn
      # delete by query proxyIn_ssi: internal_uri
      
      if RSolr.respond_to?(:solr_escape)
        # Use newer escape method, assuming the app including the cul_hydra engine is using a newer version of RSolr
        conn.delete_by_query("proxyIn_ssi:#{RSolr.solr_escape(internal_uri())}")
      else
        # Older escape method can throw deprecation warnings
        conn.delete_by_query("proxyIn_ssi:#{RSolr.escape(internal_uri())}")
      end

      # reindex proxies
      proxy_docs = proxies().collect {|p| p.to_solr}
      conn.add(proxy_docs, params: {softCommit: true})
      conn.commit
    end
  end

  # validators built for [0..1] RELS properties
  validates_with singular_rel_validator([:schema_image])
end
