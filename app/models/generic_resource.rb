require "mime/types"
require "uri"
require "open-uri"
require "tempfile"
require "active_fedora_finders"
class GenericResource < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include Cul::Hydra::Models::Common
  include Cul::Hydra::Models::ImageResource
  include Cul::Hydra::Models::RelsInt
  include Cul::Hydra::Fedora::UrlHelperBehavior

  has_and_belongs_to_many :containers, :property=>:cul_member_of, :class_name=>'ActiveFedora::Base'

  IMAGE_EXT = {"image/bmp" => 'bmp', "image/gif" => 'gif', "image/jpeg" => 'jpg', "image/png" => 'png', "image/tiff" => 'tif', "image/x-windows-bmp" => 'bmp'}
  WIDTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_width))
  LENGTH = RDF::URI(ActiveFedora::Predicates.find_graph_predicate(:image_length))

  has_datastream :name => "content", :type=>::ActiveFedora::Datastream, :versionable => true
  has_metadata :name => "accessControlMetadata", :type=>Cul::Hydra::Datastreams::AccessControlMetadata, :versionable => false

  rdf_types(RDF::Cul.Resource)
  rdf_types(RDF::PCDM.Object)

  def assert_content_model
    super
    add_relationship(:rdf_type, RDF::Cul.Resource.to_s)
  end

  def route_as
    "resource"
  end

  def index_type_label
    "FILE ASSET"
  end

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super

    unless solr_doc["extent_ssim"] || self.datastreams["content"].nil?
      if self.datastreams["content"].dsSize.to_i > 0
        solr_doc["extent_ssim"] = [self.datastreams["content"].dsSize]
      else
        repo = ActiveFedora::Base.connection_for_pid(pid)
        ds_parms = {pid: pid, dsid: "content", method: :head}
        repo.datastream_dissemination(ds_parms) do |res|
          solr_doc["extent_ssim"] = res['Content-Length']
        end
      end
    end

    if (service_ds = self.service_datastream)
      solr_doc['service_dslocation_ss'] = service_ds.dsLocation
    end
    solr_doc["fulltext_tesim"] = []
    unless self.datastreams["fulltext"].nil?
      solr_doc["fulltext_tesim"].concat(solr_doc["title_display_ssm"]) unless solr_doc["title_display_ssm"].nil? or solr_doc["title_display_ssm"].length == 0
      utf8able = Cul::Hydra::Datastreams::EncodedTextDatastream.utf8able!(self.datastreams["fulltext"].content)
      solr_doc["fulltext_tesim"] << utf8able.encode(Encoding::UTF_8)
    end
    relationships(:original_name).each do |original_name|
      solr_doc["original_name_tesim"] ||= []
      original_name = original_name.object.to_s.split('/').join(' ')
      solr_doc["original_name_tesim"] << original_name.strip
    end

    solr_doc['access_control_levels_ssim'] ||= [Cul::Hydra::AccessLevels::ACCESS_LEVEL_PUBLIC]
    solr_doc['access_control_permissions_bsi'] = !!solr_doc['access_control_permissions_bsi']
    solr_doc
  end

  def linkable_resources
    # let's start with the known DSIDs from lindquist, then work our way back to parsing the solrized relsint
    results = []
    if (rels = rels_int.instance_variable_get :@solr_hash)
      # this was loaded from solr
      rels.each do |dsuri, props|
        if dsuri =~ /\/content$/ or not props[FORMAT_OF_PREDICATE].blank?
          dsid =  dsuri.split('/')[-1]
          res = datastream_as_resource(dsid, props.with_indifferent_access)
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
        props = {extent: [], image_width: [], image_length: []}
        props[:extent] << extent_rel.object.to_s unless extent_rel.blank?
        props[:image_width] << width_rel.object.to_s unless width_rel.blank?
        props[:image_length] << length_rel.object.to_s unless length_rel.blank?
        results << datastream_as_resource(dsid, props)
      end
    end
    results
  end

  def closed?
    return access_levels.map(&:downcase).include?('closed')
  end

  def access_levels
    acm = datastreams['accessControlMetadata']
    return [] if acm.content.blank?
    return acm.to_solr.fetch('access_control_levels_ssim', [])
  end

  def service_datastream
    # we have to 'manually' query the graph because rels_int doesn't support subject pattern matching
    args = [:s, rels_int.to_predicate(:format_of), RDF::URI.new("#{internal_uri}/content")]
    query = RDF::Query.new { |q| q << args }
    candidates = query.execute(rels_int.graph).map(&:to_hash).map do |hash|
      hash[:s]
    end
    args = [:s, rels_int.to_predicate(:rdf_type), RDF::URI.new("http://pcdm.org/use#ServiceFile")]
    query = RDF::Query.new { |q| q << args }
    candidates &= query.execute(rels_int.graph).map(&:to_hash).map do |hash|
      hash[:s]
    end
    candidate_dsid = candidates.first && candidates.first.to_s.split('/')[-1]
    return datastreams[candidate_dsid] if datastreams.keys.include? candidate_dsid
    return nil
  end

  def with_ds_resource(ds_id, fedora_content_filesystem_mounted=false, &block)
    ds = self.datastreams[ds_id]

    # If the dsLocation starts with the pid, that means that we're dealing with an internally-managed ds,
    # so we can't reference the file directly even if we do have the fedora content filesystem mounted.
    if ! ds.dsLocation.start_with?(self.pid) && fedora_content_filesystem_mounted
      if ds.dsLocation =~ /^file:\//
        dsLocation = ds.dsLocation.sub(/^file:\/+/,'/')
        path = URI.unescape(dsLocation)
      else
        path = ds.dsLocation
      end

      yield(path)
    else
      internal_uri = "info:fedora/#{self.pid}/#{ds_id}"
      # No local fedora mount, need to download content over http[s]

      file_basename = File.basename(ds.dsLocation.gsub(/^file:/,''))
      file_extension = File.extname(file_basename)

      # In some cases, we actually do want to know the original extension of the file, so we'll preserve it in the temp file filename
      temp_file = Tempfile.new([file_basename, file_extension])
      begin
        parts = internal_uri.split('/')
        open(temp_file.path, 'wb') do |blob|
          repo = ActiveFedora::Base.connection_for_pid(parts[1])
          repo.datastream_dissemination({:dsid=>parts[2], :pid=>parts[1], :finished=>false}) do |res|
            res.read_body do |seg|
              blob << seg
            end
          end
        end
        yield(temp_file.path)
      ensure
        temp_file.unlink
      end
    end

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
    if res[:file_size] == "0" and props[:extent]
      res[:file_size] = (props[:extent].first || "0")
    end
    res[:size] = (res[:file_size].to_i / 1024).to_s + " Kb"
    res[:width] = (props[:image_width] and props[:image_width].first) || "0"
    res[:height] = (props[:image_length] and props[:image_length].first) || "0"
    res[:dimensions] = "#{res[:width]} x #{res[:height]}"
    base_filename = pid.gsub(/\:/,"")
    res[:filename] = base_filename + "." + dsid + "." + ds.mimeType.gsub(/^[^\/]+\//,"")
   res
  end
end
