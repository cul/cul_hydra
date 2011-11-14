require "active-fedora"
require "cul_scv_hydra"
require 'uri'
require 'rdf'
module Cul
  module Scv
  module Hydra
  module ActiveFedora
    require 'cul_scv_hydra/active_fedora/model.rb'
    AGGREGATOR_TYPE = (URI.parse("http://purl.oclc.org/NET/CUL/Aggregator"))
    RESOURCE_TYPE = (URI.parse("http://purl.oclc.org/NET/CUL/Resource"))
    module ModelMethods
      module ClassMethods
        def pid_namespace
          "ldpd"
        end
      end
      def self.included(mod)
        mod.extend(ClassMethods)
        if mod.respond_to? :has_relationship
          mod.has_relationship "containers", :cul_member_of
          mod.has_relationship "rdf_type", :rdf_type
        end
        if mod.respond_to? :has_metadata
          mod.has_metadata :name => "DC", :type=>Cul::Scv::Hydra::Om::DCMetadata
          mod.has_metadata :name => "descMetadata", :type=>Cul::Scv::Hydra::Om::ModsDocument
          mod.has_metadata :name => "rightsMetadata", :type=>::Hydra::RightsMetadata
        end
      end

      def aggregator!
        add_relationship(:rdf_type, AGGREGATOR_TYPE.to_s)
        @metadata_is_dirty = true
        update
      end

      def resource!
        add_relationship(:rdf_type, RESOURCE_TYPE.to_s)
        @metadata_is_dirty = true
        update
      end

      def resources(opts={})
        if self.respond_to? :parts # aggregator
          parts(opts)
        else
          logger.warn "parts not defined; was this a SemanticNode?"
          []
        end
      end
      def route_as
        "default"
      end
      def cmodel_pid(klass)
        klass.pid_namespace + ":" + klass.name.split("::")[-1]
      end
      def to_solr(solr_doc = Hash.new, opts={})
        sdoc = super
        if self.datastreams.include? "descMetadata"
          sdoc[:descriptor] = ["mods"]
        else
          sdoc[:descriptor] = ["dublin core"]
        end
        sdoc[:format] = [self.route_as]
        sdoc
      end
    end
  end
end
end
end
