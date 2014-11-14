# A named graph describing the location of a Resource in a virtual nested structure
require 'digest'
module ORE
class Proxy < ActiveTriples::Resource
  include Digest
  include Solrizer::Common
  include ActiveFedora::Rdf::Indexing

  module Id
    class Descriptor < Solrizer::Descriptor
      def name_and_converter(field_name, field_type)
        ['id']
      end
    end
    def self.id_for(proxy_in, proxy_for)
      path = proxy_for.to_s
      path = path.sub(/^info.fedora\/[^\/]+\/structMetadata\//,'')
      "urn:proxy:#{proxy_in ? Digest::MD5.hexdigest(proxy_in.to_s) : '' }:#{path}"
    end
  end
  def self.type
    RDF::ORE.Proxy
  end
  property :id, predicate: RDF.nodeID, multivalue: false do |ix|
    ix.as Id::Descriptor.new
  end
  property :isAggregatedBy, predicate: RDF::ORE.isAggregatedBy, multivalue: false do |ix|
    ix.as :stored_sortable
  end
  property :lineage, predicate: RDF::ORE.lineage, multivalue: false do |ix|
    ix.as :stored_sortable
  end
  property :proxyFor, predicate: RDF::ORE.proxyFor, multivalue: false do |ix|
    ix.as :stored_sortable
  end
  property :proxyIn, predicate: RDF::ORE.proxyIn, multivalue: false do |ix|
    ix.as :stored_sortable
  end
  property :index, predicate: RDF::OLO.index, multivalue: false do |ix|
    ix.as :stored_sortable
    ix.type :integer
  end
  property :format, predicate: RDF::DC.format, multivalue: false do |ix|
    ix.as :stored_sortable
  end
  property :extent, predicate: RDF::DC.extent, multivalue: false do |ix|
    ix.as :displayable
  end
  property :label, predicate: RDF::RDFS.label, multivalue: false do |ix|
    ix.as :stored_sortable
  end
  property :hasModel, predicate: RDF::FCREPO3::MODEL.hasModel, multivalue: false do |ix|
    ix.as :stored_sortable
  end

  def initialize(proxy_resource_uri, graph_context_uri, *args)
    proxy_resource_uri = RDF::URI(proxy_resource_uri)
    super(proxy_resource_uri,*args)
    update(RDF::Statement(rdf_subject,RDF.nodeID,proxy_resource_uri))
    self.proxyIn = graph_context_uri
    self.proxyFor = proxy_resource_uri
  end

  # override to obscure attempts to identify a containing Datastream
  def apply_prefix(name)
    name
  end

  def resource
    self
  end

  def to_json
    to_solr.with_indifferent_access
  end

  def to_solr(solr_doc = {}) # :nodoc:
    fields.each do |field_key, field_info|
      values = resource.get_values(field_key.to_sym).result || []
      values = [values] unless values.is_a? Array
      values.each do |val|
        if val.kind_of? RDF::URI
          val = val.to_s 
        elsif val.kind_of? ActiveTriples::Resource
          val = val.solrize
        end
        self.class.create_and_insert_terms(apply_prefix(field_key), val, field_info[:behaviors], solr_doc)
      end
    end
    solr_doc
  end
# returns a Hash, e.g.: {field => {:values => [], :type => :something, :behaviors => []}, ...}
  def fields
    field_map = {}.with_indifferent_access
    insert_field_map(:type, type_config(),field_map)
    self.class.properties.each do |name, config|
      insert_field_map(name, config, field_map)
    end
    field_map
  end

  def insert_field_map(name, config, field_map={})
    type = config[:type]
    behaviors = config[:behaviors]
    return field_map unless type and behaviors
    return field_map if config[:class_name] && config[:class_name] < ActiveFedora::Base
    resource.query(:subject => rdf_subject, :predicate => config[:predicate]).each_statement do |statement|
      field_map[name] ||= {:values => [], :type => type, :behaviors => behaviors, term: config[:term]}
      field_map[name][:values] << statement.object.to_s
    end
    field_map
  end

  def type_config
    @type_node_config ||= begin
      config = ActiveTriples::NodeConfig.new(:type, RDF.type)
      config.with_index {|ix| ix.as :symbol }
      config
    end
  end

end
end