require "active-fedora"
require "active_fedora_finders"
class Concept < GenericAggregator
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Hydra::Models::Common

  has_and_belongs_to_many :containers, :property=>:cul_member_of, :class_name=>'ActiveFedora::Base'

  def route_as
    "concept"
  end

  def index_type_label
    "CONCEPT"
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super(solr_doc, opts)
    solr_doc
  end
end
