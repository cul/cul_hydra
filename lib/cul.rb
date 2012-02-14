require "active-fedora"
require 'uri'
module Cul
  module Model
    module Core
      AGGREGATOR_TYPE = URI.parse("http://purl.oclc.org/NET/CUL/Aggregator")
      RESOURCE_TYPE = URI.parse("http://purl.oclc.org/NET/CUL/Resource")
      module CoreModelMethods
        def self.included(mod)
          if mod.respond_to? :has_relationship
            mod.has_relationship "containers", :cul_member_of
          end
        end
        def resources(opts={})
          if self.respond_to? :parts # aggregator
            parts(opts)
          else
            logger.warn "parts not defined; was this a SemanticNode?"
            []
          end
        end
        def cmodel_pid(klass)
          klass.pid_namespace + ":" + klass.name.split("::")[-1]
        end
        def datastreams_in_fedora
          mds = {}
          self.datastreams_xml['datastream'].each do |ds|
            dsid = ds["dsid"]
            ds.merge!({:pid => self.pid, :dsID => dsid, :dsLabel => ds["label"]})
            if dsid == "RELS-EXT" 
              mds.merge!({dsid => ActiveFedora::RelsExtDatastream.new(ds)})
            else
              if self.class.ds_specs.has_key? dsid
                mds.merge!({dsid => self.class.ds_specs[dsid][0].new(ds)})
              else
                mds.merge!({dsid => ActiveFedora::Datastream.new(ds)})
              end
            end
            mds[dsid].new_object = false
          end
          mds
        end
      end
    end
    module Image
    end
  end
  module Om
    module Scv
    end
  end
  require 'cul/active_fedora_helper'
  require 'cul/aggregator'
  require 'cul/aggregator_controller_helper'
  require 'cul/dcdocument'
  require 'cul/resources_helper'
end
