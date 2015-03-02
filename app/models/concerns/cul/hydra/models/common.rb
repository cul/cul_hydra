require 'active-fedora'
require 'uri'
module Cul::Hydra::Models::Common
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :create
    has_metadata :name => "DC", :type=>Cul::Hydra::Datastreams::DCMetadata, :versionable => true
    has_metadata :name => "descMetadata", :type=>Cul::Hydra::Datastreams::ModsDocument, :versionable => true
    has_metadata :name => "rightsMetadata", :type=>::Hydra::Datastream::RightsMetadata, :versionable => true
    has_many :publishers, :property => :publisher, :class_name=>'ActiveFedora::Base'
  end

  module ClassMethods
    def pid_namespace
      'ldpd'
    end

  end

  # A Fedora object label can only contain a string value of up to 255 characters.  If we try to
  # set a longer value, it causes errors upon object save.  Truncate labels to 255 characters.
  # Note: this method maps to a method_missing hanlder that converts input into a String, so
  # we use the super method first, and then post-process the output of that super method call.
  def label=(new_label)
    super(new_label)
    super(self.label[0,255])
  end

  def rdf_type
    relationships[:rdf_type]
  end

  def initialize(attrs = nil)
    attrs = {} if attrs.nil?
    attrs[:namespace] = self.class.pid_namespace unless attrs[:namespace]
    super
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

  # set the index type label and any RI-based fields
  def set_size_labels(solr_doc={})
    solr_doc["index_type_label_ssi"] = [self.index_type_label]
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super(solr_doc, opts)

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

    if solr_doc["contributor_ssim"].present?
      if solr_doc["contributor_ssim"].is_a?(Array)
        solr_doc["contributor_first_si"] = solr_doc["contributor_ssim"].first
      else
        solr_doc["contributor_first_si"] = solr_doc["contributor_ssim"]
      end
    end


    solr_doc["format_ssi"] = [self.route_as]

    set_size_labels(solr_doc)

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
    {:asset=>("cul_scv_hydra/crystal/kmultiple.png"),:mime_type=>"image/png"}
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

  def legacy_content_path(ds, ds_root=ActiveFedora.config.credentials[:datastreams_root])
    unless ds.controlGroup == 'M'
      return ds.dsLocation
    end
    cd = ds.dsCreateDate
    tz = ActiveFedora.config.credentials[:time_zone]
    tzi = ActiveSupport::TimeZone.find_tzinfo(tz)
    ld = tzi.utc_to_local(cd)
    month = (ld.month < 10) ? "0#{ld.month}" : ld.month.to_s
    day = (ld.day < 10) ? "0#{ld.day}" : ld.day.to_s
    hour = (ld.hour < 10) ? "0#{ld.hour}" : ld.hour.to_s
    min = (ld.min < 10) ? "0#{ld.min}" : ld.min.to_s
    return File.join(ds_root,"#{ld.year}/#{month}#{day}/#{hour}/#{min}", ds.dsLocation.sub(':','_'))
  end
end