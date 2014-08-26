require "cul_image_props"
require "mime/types"
require "uri"
require "open-uri"
require "tempfile"
require "active_fedora_finders"
class GenericResource < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::Models::Common
  include Cul::Scv::Hydra::Models::ImageResource
  include Cul::Scv::Fedora::UrlHelperBehavior
  include ::ActiveFedora::RelsInt

  has_and_belongs_to_many :containers, :property=>:cul_member_of, :class_name=>'ActiveFedora::Base'

  IMAGE_EXT = {"image/bmp" => 'bmp', "image/gif" => 'gif', "image/jpeg" => 'jpg', "image/png" => 'png', "image/tiff" => 'tif', "image/x-windows-bmp" => 'bmp'}
  WIDTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_width))
  LENGTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_length))

  has_datastream :name => "content", :type=>::ActiveFedora::Datastream, :versionable => true

  def assert_content_model
    super
    add_relationship(:rdf_type, Cul::Scv::Hydra::ActiveFedora::RESOURCE_TYPE.to_s)
  end

  def route_as
    self.zooming? ? "zoomingimage" : "resource"
  end

  def index_type_label
    "FILE RESOURCE"
  end

  def to_solr(solr_doc = Hash.new, opts={})
    super
    unless solr_doc["extent_ssi"] || self.datastreams["content"].nil?
      solr_doc["extent_ssi"] = [self.datastreams["content"].size]
    end
    solr_doc
  end

  def thumbnail_info
    thumb = relsint.relationships(datastreams['content'],:foaf_thumb).first
    if thumb
      t_dsid = thumb.object.to_s.split('/')[-1]
      return {:url=>"#{ActiveFedora.fedora_config[:url]}/objects/#{pid}/datastreams/#{t_dsid}/content",:mime=>datastreams[t_dsid].mimeType}
    else
      return {:url=>image_url("cul_scv_hydra/crystal/file.png"),:mime=>'image/png'}
    end
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super
    unless solr_doc["extent_ssim"] || self.datastreams["content"].nil?
      solr_doc["extent_ssim"] = [self.datastreams["content"].size]
    end
    if self.zooming?
      fz = rels_int.relationships(datastreams['content'], :foaf_zooming).first.object.to_s.split('/')[-1]
      ds = datastreams[fz]
      unless ds.nil?
        rft_id = ds.controlGroup == 'E' ? datastreams[fz].dsLocation : legacy_content_path(ds,'info:fedora/datastreams/')
        solr_doc['rft_id_ss'] = rft_id
      end
    end
    solr_doc
  end

  def thumbnail_info
    thumb = rels_int.relationships(datastreams['content'],:foaf_thumbnail).first
    if thumb
      t_dsid = thumb.object.to_s.split('/')[-1]
      t_url = "#{ActiveFedora.fedora_config.credentials[:url]}/objects/#{pid}/datastreams/#{t_dsid}/content"
      return {:url=>t_url,:mime=>datastreams[t_dsid].mimeType}
    elsif self.zooming?
      t_dsid = rels_int.relationships(dsuri, :foaf_zooming).first.object.to_s.split('/')[-1]
      t_parms = DJATOKA_THUMBNAIL_PARMS.merge({"rft_id" => datastreams[t_dsid].dsLocation})
      url = "#{DJATOKA_BASE_URL}?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }"
      {:url => url, :mime => t_parms["svc.format"]}
    else
      return {:asset => "cul_scv_hydra/crystal/file.png",:mime=>'image/png'}
    end
  end

  def linkable_resources
    # let's start with the known DSIDs from lindquist, then work our way back to parsing the solrized relsint
    results = []
    if (rels = rels_int.instance_variable_get :@solr_hash)
      # this was loaded from solr
      rels.each do |dsuri, props|
        if dsuri =~ /\/content$/ or not props[FORMAT_OF_PREDICATE].blank?
          dsid =  dsuri.split('/')[-1]
          res = datastream_as_resource(dsid, props)
          results << res
        end
      end
    else
      content_uri = RDF::URI("info:fedora/#{self.pid}/content")
      dsuris = [content_uri]
      results = []
      # read the graph
      datastreams.each do |k, v|
        rels = rels_int.relationships(v, :format_of, content_uri)
        dsuris << rels[0].subject unless rels.blank?
      end

      dsuris.each do |dsuri|
        dsid = dsuri.to_s.split('/')[-1]
        width_rel = rels_int.relationships(dsuri, :image_width)[0]
        length_rel = rels_int.relationships(dsuri, :image_length)[0]
        extent_rel = rels_int.relationships(dsuri, :extent)[0]
        props = {EXTENT_PREDICATE => [], WIDTH_PREDICATE => [], LENGTH_PREDICATE => []}
        props[EXTENT_PREDICATE] << extent_rel.object.to_s unless extent_rel.blank?
        props[WIDTH_PREDICATE] << width_rel.object.to_s unless width_rel.blank?
        props[LENGTH_PREDICATE] << length_rel.object.to_s unless length_rel.blank?
        results << datastream_as_resource(dsid, props)
      end
    end
    results
  end

  def zooming?
    !rels_int.relationships(datastreams['content'], :foaf_zooming).first.blank?
  end

  private
  def datastream_as_resource(dsid, props={})
    ds = datastreams[dsid]
    raise "No resource at info:fedora/#{pid}/#{dsid}" unless ds
    res = {}
    res[:uri] = self.pid
    res[:block] = dsid
    res[:mime_type] = ds.mimeType
    res[:content_models] = ["Datastream"]
    res[:file_size] = ds.dsSize.to_s
    if res[:file_size] == "0" and props[EXTENT_PREDICATE]
      res[:file_size] = (props[EXTENT_PREDICATE].first || "0")
    end
    res[:size] = (res[:file_size].to_i / 1024).to_s + " Kb"
    res[:width] = props[WIDTH_PREDICATE].first || "0"
    res[:height] = props[LENGTH_PREDICATE].first || "0"
    res[:dimensions] = "#{res[:width]} x #{res[:height]}"
    base_filename = pid.gsub(/\:/,"")
    res[:filename] = base_filename + "." + dsid + "." + ds.mimeType.gsub(/^[^\/]+\//,"")
   res
  end
end
