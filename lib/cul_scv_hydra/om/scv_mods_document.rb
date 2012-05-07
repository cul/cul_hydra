require 'active-fedora'
require 'solrizer'
require 'cul_scv_hydra/solrizer'
module Cul
module Scv
module Hydra
module Om
  class ModsDocument < ::ActiveFedora::NokogiriDatastream
    include OM::XML::Document
    include Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer

    after_save :action_after_save

    set_terminology do |t|
      t.root(:path=>"mods",
             :xmlns=>"http://www.loc.gov/mods/v3",
             :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-4.xsd")
      
      t.main_title_info(:path=>'titleInfo', :index_as=>[:not_searchable], :attributes=>{:type=>:none}){
        t.main_title(:path=>"title", :index_as=>[:displayable,:searchable, :sortable])
      }
      
      t.search_title_info(:path=>'titleInfo', :index_as=>[:not_searchable]){
        t.search_title(:path=>'title', :index_as=>[:searchable])
      }
      t.project(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Project"}, :index_as=>[:not_searchable]){
        t.project_title_info(:path=>'titleInfo', :index_as=>[:not_searchable]){
          t.lib_project(:path=>'title',:index_as=>[:displayable, :searchable])
          t.lib_project_facet(:path=>'title', :index_as=>[:facetable, :not_searchable],:variant_of=>{:field_base=>'lib_project',:map=>:project_facet})
        }
      }
      t.collection(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Collection"}, :index_as=>[:not_searchable]){
        t.collection_title_info(:path=>'titleInfo', :index_as=>[:not_searchable]){
          t.lib_collection(:path=>'title', :index_as=>[:facetable, :displayable])
        }
      }
      t.title(:proxy=>[:mods,:main_title_info,:main_title], :index_as=>[:displayable,:searchable, :sortable])
      t.lib_project(:proxy=>[:project,:project_title_info, :lib_project])
      t.lib_collection(:proxy=>[:collection,:collection_title_info, :lib_collection])
# pattern matches
      t.identifier(:path=>"identifier", :attributes=>{:type=>"local"}, :data_type=>:symbol)
      t.identifier_text(:ref=>:identifier, :index_as=>[:not_searchable, :textable])
      t.clio(:path=>"identifier", :attributes=>{:type=>"CLIO"}, :data_type=>:symbol)
      t.abstract
      t.subject {
        t.topic
      }
      t.type_of_resource(:path=>"typeOfResource", :index_as=>[:not_searchable])
      t.physical_description(:path=>"physicalDescription", :index_as=>[:not_searchable]){
        t.form_marc(:path=>"form", :attributes=>{:authority=>"marcform"}, :index_as=>[:not_searchable])
        t.form_aat(:path=>"form", :attributes=>{:authority=>"aat"}, :index_as=>[:not_searchable])
        t.form(:attributes=>{:authority=>:none}, :index_as=>[:not_searchable])
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
        t.map_facet(:path=>"physicalLocation",:attributes=>{:authority=>"marcorg"}, :index_as=>[:facetable], :variant_of=>{:field_base=>'lib_repo',:map=>:marc_to_facet})
        t.map_display(:path=>"physicalLocation",:attributes=>{:authority=>"marcorg"}, :index_as=>[:displayable, :not_searchable], :variant_of=>{:field_base=>'lib_repo',:map=>:marc_to_display})
        t.shelf_locator(:path=>"shelfLocator", :index_as=>[:not_searchable, :textable])
      }
      t.name_personal(:path=>'name',:attributes=>{:type=>'personal'}, :index_as=>[:not_searchable]){
        t.name_part(:path=>'namePart', :index_as=>[:facetable, :displayable, :searchable], :variant_of=>{:field_base=>:lib_name})
      }
      t.name_corporate(:path=>'name',:attributes=>{:type=>'corporate'}, :index_as=>[:not_searchable]){
        t.name_part(:path=>'namePart', :index_as=>[:facetable, :displayable, :searchable], :variant_of=>{:field_base=>:lib_name})
      }
      t.note(:path=>"note", :index_as=>[:not_searchable, :textable])
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
      t.language_term(:proxy=>[:record_info, :language_of_cataloging, :language_term])
      t.language_code(:proxy=>[:record_info, :language_of_cataloging, :language_code])

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
           "xmlns:xlink"=>"http://www.w3.org/1999/xlink",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance"){
        }
      end
      builder.doc.encoding = 'UTF-8'
      # for some reason, this is the only way to get an equivalent nokogiri root node; the attribute can't be in the original builder call
      builder.doc.root["xsi:schemaLocation"] = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd'
      return builder.doc
    end
    def action_after_save
      self.dirty= false
    end
    def method_missing method, *args
      query = false
      _mname = method.id2name
      if _mname[-1,1] == '?'
        query = true
        _mname = _mname[0,_mname.length-1]
      end
      _msym = _mname.to_sym
      has_term = self.class.terminology.has_term?(_msym)
      return false if query and not has_term
      _r = super(_mname.to_sym, *args)
      if query
        _r.length > 0
      else
        _r
      end
    end
  end
end
end
end
end
