require "active-fedora"
require "active_fedora_finders"
class GenericAggregator < ::ActiveFedora::Base
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::Models::Common
  include Cul::Scv::Hydra::Models::Aggregator

  has_many :parts, :property => :cul_member_of, :class_name=>'ActiveFedora::Base'
  has_many :publishers, :property => :publisher, :class_name=>'ActiveFedora::Base'

  def route_as
    "multipartitem"
  end

  def index_type_label
    riquery = Cul::Scv::Hydra::Models::MEMBER_ITQL.gsub(/%PID%/, self.pid)
    begin
      docs = Cul::Scv::Fedora.repository.find_by_itql riquery, limit: 2, format: 'count/json'
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
    count = Cul::Scv::Hydra::RisearchMembers.get_direct_member_count(pid)
    solr_doc["index_type_label_ssi"] = [type_label_for(count)]
    solr_doc["cul_number_of_members_isi"] = count
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super(solr_doc, opts)
    solr_doc
  end

end
