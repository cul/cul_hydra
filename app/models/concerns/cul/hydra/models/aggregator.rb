module Cul::Hydra::Models::Aggregator
  extend ActiveSupport::Concern
  included do
    has_and_belongs_to_many :containers, :property=>:cul_member_of, :class_name=>'ActiveFedora::Base'
    has_metadata :name => "structMetadata", :type=>Cul::Hydra::Datastreams::StructMetadata, :versionable => true, :controlGroup => 'M'
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

  def has_struct_metadata?
    return (!datastreams['structMetadata'].nil?) && datastreams['structMetadata'].has_content?
  end

  def solr_members(opts={})
    opts = {:rows=>25,:response_format=>:solr}.merge(opts)
    r = self.parts(opts)
    members = []
    r.collect {|hit| members << SolrDocument.new(hit) } unless r.blank?
    members
  end

  def members(opts={})
    parts({:response_format=>:solr}.merge(opts))
  end

  def member_ids(opts={})
    solr_members(opts).collect {|hit| hit.id}
  end

  def thumbnail_info
    members = solr_members
    if members.length == 0
      thumb = {:asset=>"cul_hydra/crystal/file.png",:mime=>'image/png'}
    else
      thumb = nil
      unless datastreams['structMetadata'].new?
        thumb = thumb_from_struct(members)
      else
        thumb =  thumb_from_members(members)
      end
    end
    return thumb || {:asset=>"cul_hydra/crystal/file.png",:mime=>'image/png'}
  end

  # a representative image URI for this object
  # defined by the predicate https://schema.org/image
  # @return [String, URI]
  def representative_image
    get_singular_rel(:schema_image)
  end

  def representative_image=(val)
    set_singular_rel(:schema_image, val)
  end

  private
  def thumb_from_struct(members)
    puts "thumb thumb_from_struct"
    sm = datastreams['structMetadata']
    first = sm.divs_with_attribute(false,'ORDER','1').first
    if first
      members.each do |member|
        puts "looking for #{first["CONTENTIDS"]} in #{member["identifier_ssim"].inspect}"
        if member["identifier_ssim"].include? first["CONTENTIDS"]
          return thumb_from_solr_doc(member)
        end
      end
      return thumb_from_solr_doc(members.first) if members.first
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
      member.thumbnail_info
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