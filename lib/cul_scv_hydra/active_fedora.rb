require "active-fedora"
require "cul_scv_hydra/om"
require 'uri'
require 'rdf'
module Cul
  module Scv
  module Hydra
  module ActiveFedora
    AGGREGATOR_TYPE = (URI.parse("http://purl.oclc.org/NET/CUL/Aggregator"))
    RESOURCE_TYPE = (URI.parse("http://purl.oclc.org/NET/CUL/Resource"))
    MEMBER_QUERY = <<-SPARQL
      SELECT ?pid WHERE { ?pid <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/%PID%> }
    SPARQL
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
      def index_type_label
        riquery = MEMBER_QUERY.gsub(/%PID%/, self.pid)
        docs = ::ActiveFedora::RubydoraConnection.instance.connection.find_by_sparql riquery
        if docs.length == 0
          label = "EMPTY"
        elsif docs.length == 1
          label = "SINGLE PART"
        else
          label = "MULTIPART"
        end
        label
      end
      def cmodel_pid(klass)
        klass.pid_namespace + ":" + klass.name.split("::")[-1]
      end
      def to_solr(solr_doc = Hash.new, opts={})
        sdoc = super
        has_desc = false
        begin
          has_desc = self.datastreams.include? "descMetadata"
          has_desc = has_desc and self.inner_object.datastreams["descMetadata"].content.length > 0
          has_desc = self.datastreams["descMetadata"].term_values(:identifier).length > 0
        rescue
          has_desc = false
        end
        if has_desc
          sdoc["descriptor"] = ["mods"]
        else
          sdoc["descriptor"] = ["dublin core"]
        end
        # if no mods, pull some values from DC
        if not (sdoc["title_display"] and sdoc["title_display"].length > 0)
          if self.dc.term_values(:title).first
            sdoc["title_display"] = [self.dc.term_values(:title).first]
          else
            sdoc["title_display"] = [self.dc.term_values(:identifier).first]
          end
          if self.dc.term_values(:relation).first
            self.dc.term_values(:relation).each {|val|
              if val =~ /clio:/
                sdoc["clio_s"] ||= []
                sdoc["clio_s"] << val.split(':')[-1]
              end
            }
          end
        end
        sdoc["format"] = [self.route_as]
        sdoc["index_type_label_s"] = [self.index_type_label]
        sdoc
      end
    end
  end
end
end
end
require 'cul_scv_hydra/active_fedora/model.rb'
