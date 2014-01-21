module Cul::Scv::Hydra::ActiveFedora::Model
class StructMetadata < ::ActiveFedora::Datastream
	def self.default_attributes
		super.merge(:controlGroup => 'M', :mimeType => 'text/xml')
  end

  def self.from_xml(xml)
    ds = self.new(nil, 'structMetadata')
    ds.content = xml.to_s
    ds
  end

  def self.root_content
    "<mets:structMap xmlns:mets=\"http://www.loc.gov/METS/\">"
  end

  def self.div_content
    "<mets:div />"
  end

  def initialize(digital_object=nil, dsid=nil, options={})
    super
  end

  def label=(value)
    struct_map["LABEL"] = value
    content_will_change!
  end

  def label
    struct_map["LABEL"]
  end

  def type=(value)
    struct_map["TYPE"] = value
    content_will_change!
  end

  def type
    struct_map["TYPE"]
  end

  def ng_xml
    @ng_xml ||= begin
      xml = Nokogiri::XML::Document.parse content
    end
  end

  def ng_xml= ng_xml
    @ng_xml = ng_xml
    content_will_change!
  end

  def struct_map
    ng_xml.css('mets|structMap').first
  end

  def serialize
    @ng_xml.nil? ? nil : @ng_xml.to_s
  end

  def serialize!
    _content = serialize
    if _content != @content
      self.content= _content
    end
  end

  def content
    super || StructMetadata.root_content
  end

  def content=(content)
    super
    @ng_xml = nil
  end

  def create_div_node(parent=nil, atts={})
    if parent.nil?
      parent = struct_map
    end
    divNode = parent.add_child(StructMetadata.div_content).first
    [:label, :order, :contentids]. each do |key|
      divNode[key.to_s.upcase] = atts[key].to_s if atts.has_key? key
    end
    content_will_change! if (divNode.document == ng_xml.document) 
    divNode
  end

  def to_solr
    {} # is there a relevant solrization of this DS?
  end

  def method_missing method, *args, &block
    if ng_xml.respond_to? method
      ng_xml.send(method, *args, &block)
    else
      super
    end
  end

end
end
