require 'active-fedora'
require 'uri'
module Cul::Hydra::Models::Common
  extend ActiveSupport::Concern

  included do
    extend ActiveModel::Callbacks
    define_model_callbacks :create
    has_metadata :name => "DC", :type=>Cul::Hydra::Datastreams::DCMetadata, :versionable => true
    has_metadata :name => "descMetadata", :type=>Cul::Hydra::Datastreams::ModsDocument, :versionable => true
    has_many :publishers, :property => :publisher, :class_name=>'ActiveFedora::Base'
    after_create :rdf_types!
  end

  module ClassMethods
    def pid_namespace
      'ldpd'
    end
    def rdf_types(type=nil)
      @rdf_types ||= []
      if type
        @rdf_types << type unless @rdf_types.include? type
      end
      @rdf_types
    end
    def singular_rel_validator(symbols = [])
      r = Class.new(ActiveModel::Validator) do
        def self.symbols=(symbols)
          @symbols = symbols
        end
        def self.symbols
          @symbols ||= []
        end
        def validate(record)
          self.class.symbols.each do |rel|
            record.errors[rel] << "#{rel} must have 0 or 1 values" unless record.relationships(rel).length < 2
          end
        end
      end
      r.symbols = symbols
      r
    end
  end

  def rdf_types!
    self.class.rdf_types.each do |type|
      add_relationship(:rdf_type, type.to_s)
    end
    @metadata_is_dirty = true
    self.save
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

    representative_child = get_representative_generic_resource
    solr_doc['representative_generic_resource_pid_ssi'] = representative_child.pid unless representative_child.nil?

    # Index URI form of pid to facilitate solr joins
    solr_doc['fedora_pid_uri_ssi'] = 'info:fedora/' + self.pid if self.pid.present?
    solr_doc['datastreams_ssim'] = self.datastreams.keys.map {|k| k.to_s }.sort

    solr_doc
  end

  # Return a representative file resource for the object
  # @param force_use_of_non_pid_identifier [Boolean] switch to require use of application id in struct map parsing
  # @return [GenericResource] a representative file resource
  # This method generally shouldn't be called with any parameters (unless we're doing testing)
  def get_representative_generic_resource(force_use_of_non_pid_identifier=false)
    return self if self.is_a?(GenericResource)

    # if there's an explicit assignment of representative image, return it
    assigned_image = get_singular_rel(:schema_image)
    return ActiveFedora::Base.find(assigned_image.split('/')[-1]) if assigned_image

    return nil unless self.is_a?(Cul::Hydra::Models::Aggregator) # Only Aggregators have struct metadata
    # If we're here, then the object was not a Generic resource.
    # Try to get child info from a structMat datastream, and fall back to
    # the first :cul_member_of child if a structMap isn't present

    # Check for the presence of a structMap and get first GenericResource in that structMap
    if self.has_struct_metadata?
      begin
        struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(self.datastreams['structMetadata'].content)
      rescue Rubydora::FedoraInvalidRequest => e
        Rails.logger.error "Error: Problem accessing struct datastream data in #{self.pid}" # More specific error notice
        raise e
      end
      ng_div = struct.first_ordered_content_div #Nokogiri node response
      found_struct_div = (! ng_div.nil?)
    else
      found_struct_div = false
    end

    if found_struct_div
      content_ids = ng_div.attr('CONTENTIDS').split(' ') # Get all space-delimited content ids
      child_obj = nil

      # Try to do a PID lookup first
      unless force_use_of_non_pid_identifier
        content_ids.each do |content_id|
          next unless content_id.match(/^([A-Za-z0-9]|-|\.)+:(([A-Za-z0-9])|-|\.|~|_|(%[0-9A-F]{2}))+$/) # Don't do a lookup on identifiers that can't possibly be valid PID (otherwise we'd encounter an error)
          child_obj ||= ActiveFedora::Base.exists?(content_id) ? ActiveFedora::Base.find(content_id) : nil
        end
      end

      # Then fall back to identifier lookup
      if child_obj.nil?
        child_pid = nil
        content_ids.each do |content_id|
          child_pid ||= Cul::Hydra::RisearchMembers.get_pid_for_identifier(content_id)
          if force_use_of_non_pid_identifier && child_pid && content_id == child_pid
            # This really only runs when we're doing testing, if we want to specifically ensure that we're searching by a non-pid identifier
            child_pid = nil
          end
        end

        if child_pid
          child_obj = ActiveFedora::Base.find(child_pid)
        end
      end

      if child_obj
        # Recursion!  Woo!
        return child_obj.get_representative_generic_resource(force_use_of_non_pid_identifier)
      else
        #Rails.logger.error "No object for dc:identifier in #{content_ids.inspect}"
        return nil
      end
    else
      # If there isn't a structMap, just get the first child
      member_pids = Cul::Hydra::RisearchMembers.get_direct_member_pids(self.pid, true)
      Rails.logger.warn "Warning: #{self.pid} is a member of itself!" if member_pids.include?(self.pid)
      if member_pids.first
        child_obj = ActiveFedora::Base.find(member_pids.first)
        return child_obj.get_representative_generic_resource
      else
        #Rails.logger.error "No child objects or resources for #{self.pid}"
        return nil
      end
    end
  rescue ActiveFedora::ObjectNotFoundError
    Rails.logger.warn "#{get_singular_rel(:schema_image)} not found in repository for #{self.pid}"
    return nil
  end

  def update_datastream_attributes(params={}, opts={})
    Rails.logger.debug "Common.update_datastream_attributes"
    result = params.dup
    params.each_pair do |dsid, ds_params|
      if datastreams.include?(dsid)
        verify_params = ds_params.dup
        changed = false
        verify_params.each { |pointer, values|
          changed ||= value_changed?(datastreams[dsid],pointer,values)
        }
        if changed
          Rails.logger.debug "Common.update_datastream_attributes calling update_indexed_attributes"
          result[dsid] = datastreams[dsid].update_indexed_attributes(ds_params)
        else
          result[dsid] = no_update(ds_params)
        end
        Rails.logger.debug "change detected? #{changed} digital_object? #{datastreams[dsid].changed?}"
      else
        result.delete(dsid)
      end
    end
    return result
  end

  def get_singular_rel(predicate)
    property = relationships(predicate).first
    return nil unless property
    return (property.kind_of? RDF::Literal) ? property.value : property
  end

  def set_singular_rel(predicate, value, literal=false)
    raise "#{predicate} is a singular property" if value.respond_to? :each
    clear_relationship(predicate)
    add_relationship(predicate, value, literal) unless value.nil? || value.empty?
  end

  private
  def value_changed?(ds,pointer,values)
    if values.is_a? Hash
      values = values.dup
    else
      values = {"0"=>values}
    end
    Rails.logger.debug "submitted values for #{pointer.inspect} : #{values.inspect}"
    return true if values["-1"]
    changed = false
    old_values = ds.get_values(pointer)
    indexed_values = {}
    old_values.each_index {|ix| indexed_values[ix.to_s] = old_values[ix] }
    indexed_values.each {|k,v|
      new_val = values.delete(k)
      Rails.logger.debug "old: #{v} new: #{new_val} changed? #{!(v.eql? new_val)}"
      changed ||= !(v.eql? new_val)
    }
    Rails.logger.debug "remaining values! #{values.inspect}" if values.length > 0
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
