require 'active-fedora'
require 'solrizer'
require 'cul_scv_hydra/solrizer'
module Cul
module Scv
module Hydra
module Om
  class ModsDocument < ::ActiveFedora::OmDatastream
    include ::OM::XML::TerminologyBasedSolrizer
    include Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer

    set_terminology do |t|
      t.root(:path=>"mods",
             :xmlns=>"http://www.loc.gov/mods/v3",
             :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-4.xsd") {
      }

      t.main_title_info(:path=>'titleInfo', :index_as=>[], :attributes=>{:type=>:none}){
        t.main_title(:path=>"title", :index_as=>[])
      }
      
      t.title(:proxy=>[:mods, :main_title_info, :main_title], :type=>:string,
       :index_as=>[:displayable, :searchable, :sortable, :textable])

      t.search_title_info(:path=>'titleInfo', :index_as=>[]){
        t.search_title(:path=>'title', :index_as=>[:searchable])
      }
      t.project(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Project"}, :index_as=>[]){
        t.project_title_info(:path=>'titleInfo', :index_as=>[]){
          t.lib_project(:path=>'title',:index_as=>[])
        }
      }
      t.collection(:path=>"relatedItem", :attributes=>{:type=>"host", :displayLabel=>"Collection"}, :index_as=>[]){
        t.collection_title_info(:path=>'titleInfo', :index_as=>[:facetable, :displayable]){
          t.lib_collection(:path=>'title', :index_as=>[])
        }
      }
      t.lib_project(:proxy=>[:project,:project_title_info],
        :index_as=>[:displayable, :searchable, :project_facetable, :textable])
      t.lib_collection(:proxy=>[:collection,:collection_title_info])
# pattern matches
      t.identifier(:path=>"identifier", :attributes=>{:type=>"local"}, :type=>:string, :index_as=>[:symbol, :textable])
      t.clio(:path=>"identifier", :attributes=>{:type=>"CLIO"}, :data_type=>:symbol, :index_as=>[:symbol, :textable])
      t.abstract
      t.subject {
        t.topic
      }
      t.type_of_resource(:path=>"typeOfResource", :index_as=>[:displayable])
      t.physical_description(:path=>"physicalDescription", :index_as=>[]){
        t.form_marc(:path=>"form", :attributes=>{:authority=>"marcform"}, :index_as=>[:displayable])
        t.form_aat(:path=>"form", :attributes=>{:authority=>"aat"}, :index_as=>[:displayable])
        t.form(:attributes=>{:authority=>:none}, :index_as=>[:displayable])
        t.form_nomarc(:path=>"form[@authority !='marcform']", :index_as=>[])
        t.extent(:path=>"extent", :index_as=>[:searchable, :displayable])
        t.reformatting_quality(:path=>"reformattingQuality", :index_as=>[:displayable])
        t.internet_media_type(:path=>"internetMediaType", :index_as=>[:displayable])
        t.digital_origin(:path=>"digitalOrigin", :index_as=>[:displayable])
      }
      t.lib_format(:proxy=>[:physical_description, :form_nomarc], :index_as=>[:displayable, :facetable])
      t.location(:path=>"location", :index_as=>[]){
        t.repo_text(:path=>"physicalLocation",:attributes=>{:authority=>:none},  :index_as=>[])
        t.lib_repo(:path=>"physicalLocation",
          :attributes=>{:authority=>"marcorg"},
          :index_as=>[])
        t.shelf_locator(:path=>"shelfLocator", :index_as=>[:textable])
      }
      t.lib_repo(:proxy=>[:location, :lib_repo], :type=>:text,
       :index_as=>[:marc_code_facetable, :marc_code_displayable, :marc_code_textable])
      t.lib_name(
        :path=>'name',:attributes=>{:type=>'personal'},
        :index_as=>[:facetable, :displayable, :searchable, :textable]){
        t.name_part(:path=>'namePart', :index_as=>[])
      }
      t.name_corporate(
        :path=>'name',:attributes=>{:type=>'corporate'}, 
        :index_as=>[:facetable, :displayable, :searchable],
        :variant_of=>{:field_base=>:lib_name}){
        t.name_part(
          :path=>'namePart',
          :index_as=>[])
      }
      t.note(:path=>"note", :index_as=>[:textable])
      t.access_condition(:path=>"accessCondition",
       :attributes=>{:type=>"useAndReproduction"},
       :index_as => [:searchable, :symbol])
      t.record_info(:path=>"recordInfo", :index_as=>[]) {
        t.record_creation_date(:path=>"recordCreationDate",:attributes=>{:encoding=>"w3cdtf"}, :index_as=>[])
        t.record_content_source(:path=>"recordContentSource",:attributes=>{:authority=>"marcorg"}, :index_as=>[])
        t.language_of_cataloging(:path=>"languageOfCataloging", :index_as=>[]){
          t.language_term(:path=>"languageTerm", :index_as=>[], :attributes=>{:type=>:none})
          t.language_code(:path=>"languageTerm",:attributes=>{:type=>'code',:authority=>"iso639-2b"}, :index_as=>[])
        }
        t.record_origin(:path=>"recordOrigin", :index_as=>[])
      }
      t.language_term(:proxy=>[:record_info, :language_of_cataloging, :language_term])
      t.language_code(:proxy=>[:record_info, :language_of_cataloging, :language_code])

      t.origin_info(:path=>"originInfo", :index_as=>[]){
        t.date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf'}, :index_as=>[])
        t.lib_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes'},
         :index_as=>[:date_sortable])
        t.start_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:keyDate=>'yes',:point=>'start'}, :index_as=>[])
        t.end_date(:path=>"dateIssued", :attributes=>{:encoding=>'w3cdtf',:point=>'end'}, :index_as=>[])
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
