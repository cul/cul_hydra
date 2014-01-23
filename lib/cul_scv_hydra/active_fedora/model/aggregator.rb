module Cul::Scv::Hydra::ActiveFedora::Model
module Aggregator
  extend ActiveSupport::Concern

  included do
    has_metadata :name => "structMetadata", :type=>Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata, :versionable => true, :controlGroup => 'M'
    has_many :parts, :property => :cul_member_of, :class_name=>'ActiveFedora::Base'
    after_create :aggregator!
  end

  def aggregator!
    add_relationship(:rdf_type, Cul::Scv::Hydra::ActiveFedora::AGGREGATOR_TYPE.to_s)
    @metadata_is_dirty = true
    update
  end

  def add_member(member, container=self)
    if container.respond_to?:internal_uri
      container = container.internal_uri
    end
    if container =~ /\A[\w\-]+:[\w\-]+\Z/
      container = "info:fedora/#{container}"
    end
    member.add_relationship(:cul_member_of, container)
    member.datastreams["RELS-EXT"].content_will_change!
    member.save
  end

  def remove_member(member, container=self)
    if container.respond_to?:internal_uri
      container = container.internal_uri
    end
    if container =~ /\A[\w\-]+:[\w\-]+\Z/
      container = "info:fedora/#{container}"
    end
    rel = ActiveFedora::Relationship.new()
    rel.subject_pid= :self
    rel.object = container
    rel.predicate = :cul_member_of
    member.remove_relationship(rel)
    member.datastreams["RELS-EXT"].content_will_change!
    member.save
  end
end
end
