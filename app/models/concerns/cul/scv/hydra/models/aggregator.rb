module Cul::Scv::Hydra::Models
module Aggregator
  extend ActiveSupport::Concern

  included do
    has_metadata :name => "structMetadata", :type=>Cul::Scv::Hydra::Datastreams::StructMetadata, :versionable => true, :controlGroup => 'M'
    has_many :parts, :property => :cul_member_of, :class_name=>'ActiveFedora::Base'
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

  private
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
