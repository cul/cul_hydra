require "active-fedora"
require "active_fedora_finders"
class AdministrativeSet < ::ActiveFedora::Base
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include Cul::Hydra::Models::Common
  include Pcdm::Models

  has_and_belongs_to_many :members, :property => :ldp_contains, :class_name=>'ActiveFedora::Base'

  rdf_types(RDF::CUL.Aggregator)
  rdf_types(RDF::PCDM.AdministrativeSet)

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

  def thumbnail_info
    members = solr_members
    if members.length == 0
      thumb = {:asset=>"cul_hydra/crystal/file.png",:mime=>'image/png'}
    else
      thumb = thumb_from_members(members)
    end
    return thumb || {:asset=>"cul_hydra/crystal/file.png",:mime=>'image/png'}
  end

  private
  def thumb_from_members(members)
    sorted = members.sort do |a,b|
      c = a['title_si'] <=> b['title_si']
      if c == 0 && a['identifier_ssim']
        if b['identifier_ssim']
          a['identifier_ssim'].delete(a.id) unless a['identifier_ssim'].length == 1
          b['identifier_ssim'].delete(a.id) unless b['identifier_ssim'].length == 1
          a['identifier_ssim'][0] <=> b['identifier_ssim'][0]
        else
          -1
        end
      else
        c
      end
    end
    thumb_from_solr_doc(sorted[0])
  end

  def thumb_from_solr_doc(solr_doc)
    if solr_doc and (member =  ActiveFedora::Base.find(solr_doc.id, :cast=>true)).respond_to? :thumbnail_info
      member.thumbnail_info
    else
      return nil
    end
  end

end