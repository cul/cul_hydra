require "active-fedora"
require 'uri'
module Cul::Scv::Hydra::ActiveFedora::Model
  module Common
    extend ActiveSupport::Concern
    
    included do
      define_model_callbacks :create

      has_relationship "containers", :cul_member_of
      has_relationship "rdf_type", :rdf_type
      has_metadata :name => "DC", :type=>Cul::Scv::Hydra::Om::DCMetadata
      has_metadata :name => "descMetadata", :type=>Cul::Scv::Hydra::Om::ModsDocument
      has_metadata :name => "rightsMetadata", :type=>::Hydra::RightsMetadata
    end
    
    module ClassMethods
      def pid_namespace
        "ldpd"
      end
    end  
    
    def initialize(attrs = nil)
      attrs = {} if attrs.nil?
      attrs[:namespace] = self.class.pid_namespace unless attrs[:namespace]
      super
    end
    
    def create
      run_callbacks :create do
        super
      end
    end

    def resources(opts={})
      if self.respond_to? :parts # aggregator
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
     else
        logger.warn "parts not defined; was this an Aggregator?"
        []
      end
    end

    def members(opts={})
      resources(opts)
    end
    
    def members_ids(opts={})
      opts = opts.merge({:response_format=>:id_array})
      resources(opts)
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
  
  def route_as
    "default"
  end
  
  def index_type_label
    riquery = Cul::Scv::Hydra::ActiveFedora::MEMBER_QUERY.gsub(/%PID%/, self.pid)
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
  
  def has_desc?
    has_desc = false
    begin
      has_desc = self.datastreams.include? "descMetadata"
      has_desc = has_desc and self.inner_object.datastreams["descMetadata"].content.length > 0
      has_desc = self.datastreams["descMetadata"].term_values(:identifier).length > 0
    rescue
      has_desc = false
    end
    has_desc
  end
  
  def to_solr(solr_doc = Hash.new, opts={})
    super
    if has_desc?
      solr_doc["descriptor_s"] = ["mods"]
    else
      solr_doc["descriptor_s"] = ["dublin core"]
    end
    # if no mods, pull some values from DC
    if not (solr_doc["title_display"] and solr_doc["title_display"].length > 0)
      if self.dc.term_values(:title).first
        solr_doc["title_display"] = [self.dc.term_values(:title).first]
      else
        solr_doc["title_display"] = [self.dc.term_values(:identifier).first]
      end
      if self.dc.term_values(:relation).first
        self.dc.term_values(:relation).each {|val|
          if val =~ /clio:/
            solr_doc["clio_s"] ||= []
            solr_doc["clio_s"] << val.split(':')[-1]
          end
        }
      end
    end
    solr_doc["format"] = [self.route_as]
    solr_doc["index_type_label_s"] = [self.index_type_label]
    solr_doc
  end
end