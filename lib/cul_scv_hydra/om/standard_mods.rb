require 'active-fedora'
require 'solrizer'
require 'cul_scv_hydra/solrizer'
module Cul
module Scv
module Hydra
module Om
  class StandardMods
    include OM::XML::Document
    include ::Solrizer::XML::TerminologyBasedSolrizer
  
    set_terminology do |t|
      t.root(:path=>"mods",
             :xmlns=>"http://www.loc.gov/mods/v3",
             :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-4.xsd")
      t.identifier(:path=>"identifier", :attributes=>{:type=>"local"}, :data_type=>:symbol)
      t.clio(:path=>"identifier", :attributes=>{:type=>"CLIO"}, :data_type=>:symbol)
      t.title_info(:path=>"titleInfo", :index_as=>[:not_searchable]) {
        t.main_title(:path=>"title", :index_as=>[:not_searchable])
      }
      t.title(:path=>'mods/oxns:titleInfo/oxns:title', :index_as=>[:searchable,:displayable, :sortable])
      t.abstract
      t.subject {
        t.topic
      }
      t.type_of_resource(:path=>"typeOfResource", :index_as=>[:not_searchable])
      t.physical_description(:path=>"physicalDescription", :index_as=>[:not_searchable]){
        t.form_marc(:path=>"form", :attributes=>{:authority=>"marcform"}, :index_as=>[:not_searchable])
        t.form_nomarc(:path=>"form[@authority !='marcform']", :index_as=>[:not_searchable, :displayable, :facetable])
        t.extent(:path=>"extent", :index_as=>[:not_searchable])
        t.reformatting_quality(:path=>"reformattingQuality", :index_as=>[:not_searchable])
        t.internet_media_type(:path=>"internetMediaType", :index_as=>[:not_searchable])
        t.digital_origin(:path=>"digitalOrigin", :index_as=>[:not_searchable])
      }
      t.lib_format(:proxy=>[:physical_description, :form_nomarc])
      t.location(:path=>"location", :index_as=>[:not_searchable]){
        t.repo_text(:path=>"physicalLocation",:attributes=>{:authority=>:none},  :index_as=>[:not_searchable])
        t.repo_code(:path=>"physicalLocation",:attributes=>{:authority=>"marcorg"}, :index_as=>[:not_searchable])
      }
      t.lib_repo_text(:ref=>[:location, :repo_text], :label=>"lib_repo", :index_as=>[:searchable])
      t.lib_repo(:ref=>[:location, :repo_code], :index_as=>[:not_searchable,:facetable, :displayable])
      t.project_host(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Project"}, :index_as=>[:not_searchable]){
        t.p_title(:path=>'titleInfo',:index_as=>[:not_searchable])
      }
      t.lib_project(:proxy=>[:project_host, :p_title],:index_as=>[:facetable,:displayable, :not_searchable])
      t.collection_host(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Collection"}, :index_as=>[:not_searchable]){
        t.c_title(:path=>'titleInfo',:index_as=>[:not_searchable])
      }
      t.lib_project(:path=>"mods/oxns:relatedItem[@type='host'][@displayLabel='Project']/oxns:titleInfo/oxns:title",:index_as=>[:facetable,:displayable, :not_searchable])
      t.lib_collection(:path=>"mods/oxns:relatedItem[@type='host'][@displayLabel='Collection']/oxns:titleInfo/oxns:title",:index_as=>[:facetable,:displayable, :not_searchable])
      t.note(:path=>"note")
      t.access_condition(:path=>"accessCondition", :attributes=>{:type=>"useAndReproduction"}, :index_as => [:searchable], :data_type => :symbol)
      t.record_info(:path=>"recordInfo", :index_as=>[:not_searchable]) {
        t.record_creation_date(:path=>"recordCreationDate",:attributes=>{:encoding=>"w3cdtf"}, :index_as=>[:not_searchable])
        t.record_content_source(:path=>"recordContentSource",:attributes=>{:authority=>"marcorg"}, :index_as=>[:not_searchable])
        t.language_of_cataloging(:path=>"languageOfCataloging", :index_as=>[:not_searchable]){
          t.language_term(:path=>"languageTerm", :index_as=>[:not_searchable], :attributes=>{:type=>:none})
          t.language_code(:path=>"languageTerm",:attributes=>{:type=>'code',:authority=>"iso639-2b"}, :index_as=>[:not_searchable])
        }
        t.record_origin(:path=>"recordOrigin", :index_as=>[:not_searchable])
      }

      t.origin_info(:path=>"originInfo", :index_as=>[:not_searchable]){
        t.date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf'}, :index_as=>[:not_searchable])
        t.key_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes'}, :index_as=>[:not_searchable])
        t.start_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes',:point=>'start'}, :index_as=>[:not_searchable])
        t.end_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:point=>'end'}, :index_as=>[:not_searchable])
      }
    end
  
    def self.xml_template
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(:version=>"3.4", 
           "xmlns"=>"http://www.loc.gov/mods/v3",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance"){
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
end
