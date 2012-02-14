module Cul
module Model
module AggregatorMethods
  def self.included(mod)
    if mod.respond_to? :has_relationship
      mod.has_relationship "parts", :cul_member_of, :inbound => true
    end
  end
  def add_member(member, container=self)
    if container.respond_to?:pid
      container = container.pid
    end
    member.add_relationship(:cul_member_of, container)
    member.datastreams["RELS-EXT"].dirty = true
    member.save
  end
  def remove_member(member, container=self)
    if container.respond_to?:pid
      container = container.pid
    end
    rel = ActiveFedora::Relationship.new()
    rel.subject_pid= :self
    rel.object = container
    rel.predicate = :cul_member_of
    member.remove_relationship(rel)
    member.datastreams["RELS-EXT"].dirty = true
    member.save
  end
end
end
end

