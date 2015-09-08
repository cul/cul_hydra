module Cul
module Hydra
module Datastreams
class StructMetadata < ::ActiveFedora::Datastream
  include ::ActiveFedora::Datastreams::NokogiriDatastreams

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

  def first_ordered_content_div
    divs_with_contentids_attr = self.divs_with_attribute(true, 'CONTENTIDS')
    sorted_divs_with_contentids_attr = divs_with_contentids_attr.sort_by{ |node|
      node.attr("ORDER").to_i
    }
    return sorted_divs_with_contentids_attr.first
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

  def proxies
    divs = divs_with_attribute(true)
    graph_context_uri = RDF::URI("info:fedora/#{self.pid}")
    file_system = self.type.eql?(RDF::NFO[:"#Filesystem"].to_s)
    divs.collect do |div|
      proxy_uri_chain = proxy_uri_chain_for(div)
      proxy_resource_uri = proxy_uri_chain.pop
      if div['CONTENTIDS']
        subclass = file_system ?
          NFO::FileDataObject : SC::Canvas
        proxy = subclass.new(proxy_resource_uri, graph_context_uri)
        proxy.proxyFor = RDF::URI(div['CONTENTIDS'])
      else
        subclass = file_system ?
          NFO::Folder : SC::Sequence
        proxy = subclass.new(proxy_resource_uri, graph_context_uri)
      end
      if div.parent and div.parent.name == 'div'
        proxy.belongsToContainer = proxy_uri_for(div.parent)
      end
      proxy.isPartOf = proxy_uri_chain unless proxy_uri_chain.empty?
      proxy.index = div['ORDER']
      proxy.label = div['LABEL']
      proxy
    end
  end

  def merge(*parts)
    if bad_part = parts.detect {|p| !p.is_a? StructMetadata}
      raise "Can only compose from other StructMetadata datastreams (#{bad_part.class})"
    end

    parts.each do |part|
      part.struct_map.attributes.each do |att|
        struct_map[att[0]] = att[1]
      end
      combine(part.struct_map,struct_map)
    end
    ng_xml_will_change!
    self
  end

  private
  def combine(src, target)
    src.children.each do |child|

      if child['CONTENTIDS'] and c = target.children.detect {|n| n['CONTENTIDS'].eql?child['CONTENTIDS']}
        child.attributes.each do |att|
          c[att[0]] = c[att[1]]
        end
        combine(child,c)
      elsif c = target.children.detect {|n| n['LABEL'].eql?child['LABEL'] and !n['CONTENTIDS']}
        combine(child,c)
      else
        target.add_child(child.dup.unlink)
      end
    end
  end
  def ancestors(node)
    current = node
    labels = []
    while (current.name == 'div')
      label = URI.escape(current['LABEL'])
      label = URI.escape(current['ORDER']) if label.blank?
      labels.unshift label
      current = current.parent
    end
    labels
  end
  def proxy_uri_chain_for(node)
    uris = []
    ancestors(node).inject(RDF::URI("info:fedora/#{self.pid}/#{self.dsid}")) {|m,a| (uris << m/a).last}
    uris
  end
  def proxy_uri_for(node)
    # uri = segments.inject(base_uri) {|m,a| m/a}
    ancestors(node).inject(RDF::URI("info:fedora/#{self.pid}/#{self.dsid}")) {|m,a| m/a} 
  end
end
end
end
end
