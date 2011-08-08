require 'active-fedora'
module Cul
module Om
module Scv
  class ModsDocument < ActiveFedora::NokogiriDatastream
    include OM::XML::Document
  
    set_terminology do |t|
      t.root(:path=>"mods",
             :xmlns=>"http://www.loc.gov/mods/v3",
             :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-4.xsd")
      t.local_id(:path=>"identifier", :attributes=>{:type=>"local"})
      t.clio_id(:path=>"identifier", :attributes=>{:type=>"CLIO"})
      t.title_info(:path=>"titleInfo") {
        t.title(:path=>"title")
      }
      t.main_title(:proxy=>[:title_info, :title])
      t.type_of_resource(:path=>"typeOfResource")
      t.physical_description(:path=>"physicalDescription"){
        t.form_marc(:path=>"form", :attributes=>{:authority=>"marcform"})
        t.form_aat(:path=>"form", :attributes=>{:authority=>"aat"})
        t.extent(:path=>"extent")
        t.reformatting_quality(:path=>"reformattingQuality")
        t.internet_media_type(:path=>"internetMediaType")
        t.digital_origin(:path=>"digitalOrigin")
      }
      t.location(:path=>"location"){
        t.repo_text(:path=>"physicalLocation",:attributes=>{:authority=>:none})
        t.repo_facet(:path=>"physicalLocation",:attributes=>{:authority=>"marcorg"})
      }
      t.repo_text(:proxy=>[:location, :repo_text])
      t.repo_facet(:proxy=>[:location, :repo_facet])
      t.project_host(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Project"}){
        t.title_info(:ref=>[:title_info]){
          t.project_facet(:path=>"title",:index_as=>[:facetable])
          t.project_text(:path=>"title")
        }
      }
      t.project_text(:proxy=>[:project_host, :title_info, :project_text])
      t.project_facet(:proxy=>[:project_host, :title_info, :project_facet])
      t.collection_host(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Collection"}){
        t.title_info(:ref=>[:title_info]){
          t.collection_facet(:path=>"title",:index_as=>[:facetable])
          t.collection_text(:path=>"title")
        }
      }
      t.collection_text(:proxy=>[:collection_host, :title_info, :collection_text])
      t.collection_facet(:proxy=>[:collection_host, :title_info, :collection_facet])
      t.note(:path=>"note")
      t.use_and_reproduction(:path=>"accessCondition", :attributes=>{:type=>"useAndReproduction"})
      t.record_info(:path=>"recordInfo") {
        t.record_creation_date(:path=>"recordCreationDate",:attributes=>{:encoding=>"w3cdtf"})
        t.record_content_source(:path=>"recordContentSource",:attributes=>{:authority=>"marcorg"})
        t.language_of_cataloging(:path=>"languageOfCataloging"){
          t.language_term(:path=>"languageTerm")
          t.language_code(:path=>"languageTerm",:attributes=>{:type=>'code',:authority=>"iso639-2b"})
        }
        t.record_origin(:path=>"recordOrigin")
      }
      t.language_code(:proxy=>[:record_info,:language_of_cataloging, :language_code])

      t.origin_info(:path=>"originInfo"){
        t.date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf'})
        t.key_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes'})
        t.start_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes',:point=>'start'})
        t.end_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:point=>'end'})
      }
      t.key_date(:proxy=>[:origin_info,:key_date])
      t.start_date(:proxy=>[:origin_info, :start_date])
      t.end_date(:proxy=>[:origin_info,:end_date])
    end
  
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(:version=>"3.4", 
           "xmlns"=>"http://www.loc.gov/mods/v3",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance"){
      #    xml.identifier(:type=>"local")
      #    xml.titleInfo {
      #       xml.title
      #    }
      #    xml.accessCondition(:type=>"useAndReproduction")
      #    xml.location {
      #      xml.physicalLocation(:authority=>"marcorg")
      #      xml.physicalLocation
      #    }
      #    xml.recordInfo {
      #      xml.recordCreationDate(:encoding=>"w3cdtf")
      #      xml.recordContentSource(:authority=>"marcorg")
      #      xml.languageOfCataloging {
      #        xml.languageTerm(:type=>'code', :authority=>'iso639-2b') {
      #          "eng"
      #        }
      #      }
      #      xml.recordOrigin
      #    }
        }
      end
      builder.doc.encoding = 'UTF-8'
      builder.doc.root["xsi:schemaLocation"] = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd'
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
        has_term = self.class.terminology.has_term?(_msym)

        _r = (has_term)? find_by_terms(_msym, *args) : nil
        if query
          return !( _r.nil? || _r.size()==0)
        else
          return _r
        end
      rescue
        super
      end
    end
    def update_values(params)
      super
      self.dirty = true
    end
  end
end
end
end
