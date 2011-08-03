require 'active-fedora'
module Cul
module Om
  class DCMetadata < ActiveFedora::NokogiriDatastream
    include OM::XML::Document
  
    set_terminology do |t|
      t.root(:path=>"dc",
             :xmlns=>"http://www.openarchives.org/OAI/2.0/oai_dc/",
             "xmlns:dc"=>"http://purl.org/dc/elements/1.1/",
             :schema=>"http://www.openarchives.org/OAI/2.0/oai_dc.xsd"){
      t.contributor(:path=>"dc:contributor")
      t.coverage(:path=>"dc:coverage")
      t.creator(:path=>"dc:creator")
      t.date(:path=>"dc:date")
      t.description(:path=>"dc:description")
      t.format(:path=>"dc:format")
      t.identifier(:path=>"dc:identifier")
      t.language(:path=>"dc:language")
      t.publisher(:path=>"dc:publisher")
      t.relation(:path=>"dc:relation")
      t.rights(:path=>"dc:rights")
      t.source(:path=>"dc:source")
      t.subject(:path=>"dc:subject")
      t.title(:path=>"dc:title")
      t.type(:path=>"dc:type")
      }
    end
  
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.dc(
           "xmlns"=>"http://www.openarchives.org/OAI/2.0/oai_dc/",
           "xmlns:dc"=>"http://purl.org/dc/elements/1.1/",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance"){
        }
      end
      builder.doc.encoding = 'UTF-8'
      builder.doc.root["xsi:schemaLocation"] = 'http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd'
      return builder.doc
    end
    def method_missing method, *args
      query = false
      _mname = method.id2name
      if _mname[-1,1] == '?'
        query = true
        _mname = _mname[0,_mname.length-1]
      end
      _msym = _mname.to_sym
      begin
        _r = find_by_terms(_msym, *args)
        if query
          return !( _r.nil? || _r.size()==0)
        else
          return _r
        end
      rescue
        super
      end
    end
    def update_values(args)
      super
      self.dirty = true
    end
  end
end
end
