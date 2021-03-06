require "active-fedora"
require "active_fedora_finders"
class Concept < GenericAggregator
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include Cul::Hydra::Models::Common
  include Cul::Hydra::Models::Aggregator

  rdf_types(RDF::CUL.Aggregator)
  rdf_types(RDF::PCDM.Object)

  has_file_datastream :name => "descriptionText", :type=>Cul::Hydra::Datastreams::EncodedTextDatastream,
                 :versionable => false, :label => 'Textual Description of Concept',
                 :mimeType => 'text/markdown'

  has_and_belongs_to_many :containers, :property=>:cul_member_of, :class_name=>'ActiveFedora::Base'

  def route_as
    "concept"
  end

  def index_type_label
    "CONCEPT"
  end

  def abstract
    get_singular_rel(:abstract)
  end

  def abstract=(val)
    set_singular_rel(:abstract, val, true)
  end

  def description_ds
    candidate =
      relationships(:description).select { |v| v.to_s.index(self.internal_uri.to_s) == 0 }
    candidate = candidate.first
    candidate = candidate.to_s.split('/')[2]
    datastreams[candidate] unless candidate.blank?
  end

  # a marked up description of this concept suitable for embedding in a web page
  # http://purl.org/dc/terms/description
  def description
    ds = description_ds
    return nil unless ds
    ds.content.to_s
  end

  def description=(value)
    ds = description_ds
    if value.nil? || value.empty?
      if ds
        # Datastreams don't allow empty content, so we need to delete the datastream
        datastreams['descriptionText'].delete
        clear_relationship(:description)
      end
    else
      if ds
        ds.content = value
      else
        add_relationship(:description, internal_uri.to_s + "/descriptionText")
        datastreams['descriptionText'].content =  value
      end
    end
  end

  # a human readable PREMIS restriction ('Onsite', etc.)
  # http://www.loc.gov/premis/rdf/v1#hasRestriction
  def restriction
    get_singular_rel(:restriction)
  end

  def restriction=(val)
    set_singular_rel(:restriction, val, true)
  end
  
  # a human readable URI segment for this concept
  # http://www.bbc.co.uk/ontologies/coreconcepts/slug
  def slug
    get_singular_rel(:slug)
  end

  def slug=(val)
    set_singular_rel(:slug, val, true)
  end

  # a URI property indicating the service endpoint associated with this concept
  # http://purl.org/dc/terms/source
  def source
    get_singular_rel(:source)
  end

  def source=(val)
    set_singular_rel(:source, val)
  end

  # a short or abbreviated title
  # http://purl.org/ontology/bibo/shortTitle
  def short_title
    get_singular_rel(:short_title)
  end

  def short_title=(val)
    set_singular_rel(:short_title, val, true)
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super(solr_doc, opts)
    description.tap do |description_value|
      if description_value
        unless description_ds.is_a? Cul::Hydra::Datastreams::EncodedTextDatastream
          description_value = Cul::Hydra::Datastreams::EncodedTextDatastream.utf8able!(description_value).encode(Encoding::UTF_8)
        end
        description_field_name = ::ActiveFedora::SolrService.solr_name(:description_text, :displayable)
        solr_doc[description_field_name] = description_value
      end
    end
    solr_doc
  end

  # validators built for [0..1] RELS properties
  validates_with singular_rel_validator([:abstract, :alternative, :restriction, :slug, :source])
end
