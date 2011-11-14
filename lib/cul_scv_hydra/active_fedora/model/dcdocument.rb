require "active-fedora"
require "cul_scv_hydra"
require "cul_scv_admin/core"
require "hydra"
module Cul
module Scv
module ActiveFedora
module Model
class DcDocument < ActiveFedora::Base
  include Hydra::ModelMethods
  include Cul::Model::Core::ModelMethods

  has_relationship "parts", :cul_member_of, :inbound => true

  def self.pid_namespace
    "ldpd"
  end

  def self.load_instance_from_solr(pid,solr_doc=nil)
    if solr_doc.nil?
      result = find_by_solr(pid)
      raise "Object #{pid} not found in solr" if result.nil?
      solr_doc = result.hits.first
      #double check pid and id in record match
      raise "Object #{pid} not found in Solr" unless !result.nil? && !solr_doc.nil? && pid == solr_doc[SOLR_DOCUMENT_ID]
    else
      raise "Solr document record id and pid do not match" unless pid == solr_doc[SOLR_DOCUMENT_ID]
    end
     
    create_date = solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date)].nil? ? solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date).to_s] : solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date)]
    modified_date = solr_doc[ActiveFedora::SolrService.solr_name(:system_create, :date)].nil? ? solr_doc[ActiveFedora::SolrService.solr_name(:system_modified, :date).to_s] : solr_doc[ActiveFedora::SolrService.solr_name(:system_modified, :date)]
    obj = DcDocument.new({:pid=>solr_doc[SOLR_DOCUMENT_ID],:create_date=>create_date,:modified_date=>modified_date})
    obj.new_object = false
      #set by default to load any dependent relationship objects from solr as well
    obj.load_from_solr = true
      #need to call rels_ext once so it exists when iterating over datastreams
    obj.rels_ext
    obj.datastreams.each_value do |ds|
      if ds.respond_to?(:from_solr)
        ds.from_solr(solr_doc) if ds.kind_of?(ActiveFedora::MetadataDatastream) || ds.kind_of?(ActiveFedora::NokogiriDatastream) || ( ds.kind_of?(ActiveFedora::RelsExtDatastream))
      end
    end
    obj
  end

# metadata #
  has_metadata :name => "DC", :type=>Cul::Scv::Hydra::Om::DCMetadata
  has_metadata :name => "descMetadata", :type=>Cul::Scv::Hydra::Om::ModsDocument
  has_metadata :name => "rightsMetadata", :type=>Hydra::RightsMetadata
# relationships #
  has_relationship "containers", :cul_member_of

  def resources(opts={})
    if self.respond_to? :parts
      parts(opts)
    else
      logger.warn "parts not defined; was this a SemanticNode?"
      []
    end
  end

end
end
end
end
end