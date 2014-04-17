require 'active-fedora'
require 'uri'
module Cul::Scv::Hydra::Models
module Common
  extend ActiveSupport::Concern
    DC_SPEC = {
      :name => "DC", :type=>Cul::Scv::Hydra::Datastreams::DCMetadata,
      :versionable => true, :label => 'Dublin Core Record for this object'
    }
  included do
    define_model_callbacks :create
    has_and_belongs_to_many :containers, :property=>:cul_member_of, :class_name=>'ActiveFedora::Base'
    has_metadata :name => "DC", :type=>Cul::Scv::Hydra::Datastreams::DCMetadata, :versionable => true
    #self.ds_specs['DC'] = DC_SPEC
    has_metadata :name => "descMetadata", :type=>Cul::Scv::Hydra::Datastreams::ModsDocument, :versionable => true
    has_metadata :name => "rightsMetadata", :type=>::Hydra::Datastream::RightsMetadata, :versionable => true
    
  end
    
  module ClassMethods
    def pid_namespace
      'ldpd'
    end

    # override a buggy impl in AF
    def has_datastream(args)
      unless args.has_key?(:name)
        return false
      end
      unless args.has_key?(:prefix)
        args.merge!({:prefix=>args[:name].to_s.upcase})
      end
      unless class_named_datastreams_desc.has_key?(args[:name]) 
        class_named_datastreams_desc[args[:name]] = {} 
      end
          
      args.merge!({:mimeType=>args[:mime_type]}) if args.has_key?(:mime_type)
      
      unless class_named_datastreams_desc[args[:name]].has_key?(:type) 
        #default to type ActiveFedora::Datastream
        args[:type] ||= ActiveFedora::Datastream
      end
      args[:type] = args[:type].constantize if args[:type].is_a? String
      raise args[:type] unless args[:type].name
      class_named_datastreams_desc[args[:name]]= args   
      create_named_datastream_finders(args[:name],args[:prefix])
      create_named_datastream_update_methods(args[:name])
    end
  end

  def rdf_type
    relationships[:rdf_type]
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
      logger.warn 'parts not defined; was this an Aggregator?'
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

  def route_as
    "default"
  end
  
  def index_type_label
    riquery = Cul::Scv::Hydra::Models::MEMBER_QUERY.gsub(/%PID%/, self.pid)
    begin
      docs = ::ActiveFedora::Base.connection_for_pid(self.pid).find_by_sparql riquery
    rescue Exception=>e
      docs = self.parts
    end
    if docs.size == 0
      label = "EMPTY"
    elsif docs.size == 1
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
      has_desc = has_desc and self.datastreams["descMetadata"].term_values(:identifier).length > 0
    rescue
      has_desc = false
    end
    has_desc
  end

  def to_solr(solr_doc = Hash.new, opts={})
    super
    if has_desc?
      solr_doc["descriptor_ssi"] = ["mods"]
    else
      solr_doc["descriptor_ssi"] = ["dublin core"]
    end
    # if no mods, pull some values from DC
    if (solr_doc["title_display_ssm"].nil? or solr_doc["title_display_ssm"].length == 0)
      if self.datastreams["DC"].term_values(:dc_title).first
        solr_doc["title_display_ssm"] = self.datastreams["DC"].term_values(:dc_title)
      else
        solr_doc["title_display_ssm"] = self.datastreams["DC"].term_values(:dc_identifier).reject {|dcid| dcid.eql? self.id}
      end
      solr_doc["title_si"] = self.datastreams["DC"].term_values(:dc_title).first
      if self.datastreams["DC"].term_values(:dc_relation).first
        self.datastreams["DC"].term_values(:dc_relation).each {|val|
          if val =~ /clio:/
            solr_doc["clio_ssim"] ||= []
            solr_doc["clio_ssim"] << val.split(':')[-1]
          end
        }
      end
    end
    if (solr_doc["identifier_ssim"].nil? or solr_doc["identifier_ssim"].length == 0)
        solr_doc["identifier_ssim"] = self.datastreams["DC"].term_values(:dc_identifier).reject {|dcid| dcid.eql? self.id}
    end
    if (solr_doc["title_display_ssm"].length > 1)
      solr_doc["title_display_ssm"].uniq!
    end
    solr_doc["format_ssi"] = [self.route_as]
    solr_doc["index_type_label_ssi"] = [self.index_type_label]
    
    solr_doc.each_pair {|key, value|
      if value.is_a? Array
        value.each {|v| v.strip! unless v.nil? }
      elsif value.is_a? String
        value.strip!
      end
    }
    solr_doc[:structured_bsi] = 'false' unless solr_doc.has_key? :structured_bsi
    solr_doc
  end
  
  def update_datastream_attributes(params={}, opts={})
    logger.debug "Common.update_datastream_attributes"
    result = params.dup
    params.each_pair do |dsid, ds_params| 
      if datastreams.include?(dsid)
        verify_params = ds_params.dup
        changed = false
        verify_params.each { |pointer, values|
          changed ||= value_changed?(datastreams[dsid],pointer,values)
        }
        if changed
          logger.debug "Common.update_datastream_attributes calling update_indexed_attributes"
          result[dsid] = datastreams[dsid].update_indexed_attributes(ds_params)
        else
          result[dsid] = no_update(ds_params)
        end
        logger.debug "change detected? #{changed} digital_object? #{datastreams[dsid].changed?}"
      else
        result.delete(dsid)
      end
    end
    return result
  end
  
  def thumbnail_info
    {:url=>image_url("cul_scv_hydra/crystal/kmultiple.png"),:mime_type=>"image/png"}
  end

  private
  def value_changed?(ds,pointer,values)
    if values.is_a? Hash
      values = values.dup
    else
      values = {"0"=>values}
    end
    logger.debug "submitted values for #{pointer.inspect} : #{values.inspect}"
    return true if values["-1"]
    changed = false
    old_values = ds.get_values(pointer)
    indexed_values = {}
    old_values.each_index {|ix| indexed_values[ix.to_s] = old_values[ix] }
    indexed_values.each {|k,v|
      new_val = values.delete(k)
      logger.debug "old: #{v} new: #{new_val} changed? #{!(v.eql? new_val)}"
      changed ||= !(v.eql? new_val)
    }
    logger.debug "remaining values! #{values.inspect}" if values.length > 0
    changed || (values.length > 0)
  end
 
  def no_update(ds_params)
    response = {}
    ds_params.each{|pointer, values|
      returned = []
      if values.is_a? Hash
        keys = values.keys.sort {|x,y| x.to_i <=> y.to_i}
        keys.each {|key| returned << values[key]}
      else
        returned << values
      end
      response[OM::XML::Terminology.term_hierarchical_name(pointer)] = returned
    }
  end
end
end
