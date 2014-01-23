module Cul::Scv::Hydra::ActiveFedora::Model
class StructMetadata < ::ActiveFedora::Datastream
  include NokogiriDatastreams

	def self.default_attributes
		super.merge(:controlGroup => 'M', :mimeType => 'text/xml')
  end

  def self.xml_template
    Nokogiri::XML::Document.parse("<mets:structMap xmlns:mets=\"http://www.loc.gov/METS/\">")
  end

  def self.div_template(prefix="mets")
    prefix.nil? ? '<div/>' : "<#{prefix}:div/>"
  end

  def initialize(digital_object=nil, dsid=nil, options={})
    super
  end

  # Indicates that this datastream has metadata content. 
  # @return true 
  def metadata?
    true
  end

  def autocreate?
    changed_attributes.has_key? :profile
  end

  def label=(value)
    struct_map["LABEL"] = value
    ng_xml_will_change!
  end

  def label
    struct_map["LABEL"]
  end

  def type=(value)
    struct_map["TYPE"] = value
    ng_xml_will_change!
  end

  def type
    struct_map["TYPE"]
  end

  def prefix
    prefix = nil
    ng_xml.namespaces.each do |p, href|
      prefix = p.sub(/xmlns:/,'') if href == "http://www.loc.gov/METS/"
    end
    prefix
  end

  def struct_map
    prefix = self.prefix
    path = prefix.nil? ? 'xmlns:structMap' : "#{prefix}:structMap"
    ng_xml.xpath(path, ng_xml.namespaces).first
  end

  def create_div_node(parent=nil, atts={})
    if parent.nil?
      parent = struct_map
    end
    divNode = parent.add_child(StructMetadata.div_template(parent.namespace.prefix)).first
    [:label, :order, :contentids]. each do |key|
      divNode[key.to_s.upcase] = atts[key].to_s if atts.has_key? key
    end
    ng_xml_will_change! if (divNode.document == ng_xml.document) 
    divNode
  end

  def divs_with_attribute(descend=true, name=nil, value=nil)
    prefix = self.prefix || 'xmlns'
    xpath = descend ? "//#{prefix}:div" : "/#{prefix}:structMap/#{prefix}:div"
    if !name.nil?
      xpath << "[@#{name}"
      if !value.nil?
        xpath << "='#{value}'"
      end
      xpath << ']'
    end
    ng_xml.xpath(xpath, ng_xml.namespaces)
  end

  # a convenience method for setting attributes and creating divs (if necessary) for R/V structure
  # returns the mets:structMap node
  def recto_verso!
    self.type= 'physical' unless self.type == 'physical'
    self.label= 'Sides' unless self.label == 'Sides'
    create_div_node struct_map, {:order=>'1'} unless divs_with_attribute(false,'ORDER','1').first
    create_div_node struct_map, {:order=>'2'} unless divs_with_attribute(false,'ORDER','2').first
    if (div = divs_with_attribute(false,'ORDER','1').first)
      div['LABEL'] = 'Recto' unless div['LABEL'] == 'Recto'
    end
    if (div = divs_with_attribute(false,'ORDER','2').first)
      div['LABEL'] = 'Verso' unless div['LABEL'] == 'Verso'
    end
    struct_map
  end

  def recto
    divs_with_attribute(false, 'LABEL', 'Recto').first
  end

  def verso
    divs_with_attribute(false, 'LABEL', 'Verso').first
  end

  def to_solr(doc={})
    doc[:structured_bsi] = (has_content? ? 'true' : 'false')
    doc
  end

end
end
