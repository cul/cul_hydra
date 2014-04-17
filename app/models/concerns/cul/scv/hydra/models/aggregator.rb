module Cul::Scv::Hydra::Models
module Aggregator
  extend ActiveSupport::Concern

  included do
    has_and_belongs_to_many :containers, :property=>:cul_member_of, :class_name=>'ActiveFedora::Base'
    has_metadata :name => "structMetadata", :type=>Cul::Scv::Hydra::Datastreams::StructMetadata, :versionable => true, :controlGroup => 'M'
    after_create :aggregator!
  end

  def aggregator!
    add_relationship(:rdf_type, Cul::Scv::Hydra::Models::AGGREGATOR_TYPE.to_s)
    @metadata_is_dirty = true
    self.save
  end

  def add_member(member, container=self)
    member.add_relationship(:cul_member_of, to_uri(container))
    member.datastreams["RELS-EXT"].content_will_change!
    member.save
  end

  def remove_member(member, container=self)
    rel = ActiveFedora::Relationship.new()
    rel.subject_pid= :self
    rel.object = to_uri(container)
    rel.predicate = :cul_member_of
    member.remove_relationship(rel)
    member.datastreams["RELS-EXT"].content_will_change!
    member.save
  end

  def solr_members(opts={})
    opts = {:rows=>25,:response_format=>:solr}.merge(opts)
    self.parts(opts)
    #opts = {:rows=>25,:response_format=>:solr}.merge(opts)
    #query = self.class.inbound_relationship_query(self.pid, "parts")
    #solr_result = ::ActiveFedora::SolrService.instance.conn.query(query, :rows=>opts[:rows])
    #if opts[:response_format] == :solr
    #  return solr_result
    #else
    #  if opts[:response_format] == :id_array
    #    id_array = []
    #    solr_result.hits.each do |hit|
    #      id_array << hit[SOLR_DOCUMENT_ID]
    #    end
    #    return id_array
    #  elsif opts[:response_format] == :load_from_solr || self.load_from_solr
    #    return ::ActiveFedora::SolrService.reify_solr_results(solr_result,{:load_from_solr=>true})
    #  else
    #    return ::ActiveFedora::SolrService.reify_solr_results(solr_result)
    #  end
    #end
  end

  def members(opts={})
    solr_members(opts)
  end
  
  def members_ids(opts={})
    opts = opts.merge({:response_format=>:id_array})
    solr_members(opts)
  end

  def thumbnail_info
    r = self.parts.reader(:response_format => :solr)
    members = []
    r.collect {|hit| members << SolrDocument.new(hit) } unless r.blank?
    if members.length == 0
      return {:asset=>"cul_scv_hydra/crystal/file.png",:mime=>'image/png'}
    else
      thumb = nil
      unless datastreams['structMetadata'].new?
        thumb = thumb_from_struct(members)
      else
        thumb =  thumb_from_members(members)
      end
    end
    return thumb || {:asset=>"cul_scv_hydra/crystal/file.png",:mime=>'image/png'}
  end

  private
  def thumb_from_struct(members)
    sm = datastreams['structMetadata']
    first = sm.divs_with_attribute(false,'ORDER','1').first
    if first
      members.each do |member|
        if member["identifier_ssim"].include? first["CONTENTIDS"]
          return thumb_from_solr_doc(member)
        end
      end
      return nil
    else
      return nil
    end
  end

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
      puts "thumb: " + (thumb = member.thumbnail_info).inspect
      thumb
    else
      return nil
    end
  end

  def to_uri(obj)
    if obj.respond_to? :internal_uri
      return obj.internal_uri
    end
    obj = obj.pid unless obj.is_a? String
    if obj.is_a? String and obj =~ /\A[\w\-]+:[\w\-]+\Z/
      obj = "info:fedora/#{obj}"
    end
    return obj
  end
end
end
