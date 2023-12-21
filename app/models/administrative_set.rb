require "active-fedora"
require "active_fedora_finders"
class AdministrativeSet < ::ActiveFedora::Base
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include Cul::Hydra::Models::Common
  include Pcdm::Models

  has_and_belongs_to_many :members, :property => :ldp_contains, :class_name=>'ActiveFedora::Base'

  rdf_types(RDF::Cul.Aggregator)
  rdf_types(RDF::Pcdm.AdministrativeSet)

  def route_as
    "administrative_set"
  end

  def index_type_label
    "MULTIPART"
  end

  def has_struct_metadata?
    false
  end

  def solr_members(opts={})
    opts = {:rows=>25,:response_format=>:solr}.merge(opts)
    r = self.parts(opts)
    members = []
    r.collect {|hit| members << SolrDocument.new(hit) } unless r.blank?
    members
  end
end