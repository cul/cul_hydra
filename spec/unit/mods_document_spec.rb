require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Scv::Hydra::Datastreams::ModsDocument" do

  before(:all) do

  end

  before(:each) do
    @mock_inner = double('inner object')
    @mock_inner.stub(:"new_record?").and_return(false)
    @mock_repo = double('repository')
    @mock_ds = double('datastream')
    @mock_repo.stub(:config).and_return({})
    @mock_repo.stub(:datastream_profile).and_return({})
    @mock_repo.stub(:datastream_dissemination=>'My Content')
    @mock_inner.stub(:repository).and_return(@mock_repo)
    @mock_inner.stub(:pid)
    @fixturemods = descMetadata(@mock_inner, fixture( File.join("CUL_MODS", "mods-item.xml") ) )
    item_xml = fixture( File.join("CUL_MODS", "mods-item.xml") )
    @mods_item = descMetadata(@mock_inner, item_xml)
    @mods_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-item.xml")))
    @mods_ns = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-ns.xml")))
    part_xml = fixture( File.join("CUL_MODS", "mods-part.xml") )
    @mods_part = descMetadata(@mock_inner, part_xml)
  end

  after(:all) do

  end

  it "should automatically include the necessary modules" do
    Cul::Scv::Hydra::Datastreams::ModsDocument.included_modules.should include(OM::XML::Container)
    Cul::Scv::Hydra::Datastreams::ModsDocument.included_modules.should include(OM::XML::TermValueOperators)
    Cul::Scv::Hydra::Datastreams::ModsDocument.included_modules.should include(OM::XML::Validation)
  end

  describe ".ox_namespaces" do
    it "should merge terminology namespaces with document namespaces" do
      @mods_item.ox_namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns"=>"http://www.loc.gov/mods/v3"}
    end
    it "should correctly namespace attributes" do
      result = false
      @mods_ng.css('mods').first.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          result =  node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      result.should == true
    end
  end


  describe ".find_by_terms_and_value" do
    it "should fail gracefully if you try to look up nodes for an undefined property" do
      pending "better to get an informative error?"
      @mods_item.find_by_terms_and_value(:nobody_home).should == []
    end
    it "should use Nokogiri to retrieve a NodeSet corresponding to the term pointers" do
      @mods_item.find_by_terms_and_value( :lib_project).length.should == 1
    end

    it "should allow you to search by term pointer" do
      @mods_item.ng_xml.should_receive(:xpath).with('//oxns:location/oxns:physicalLocation[@authority="marcorg"]', @mods_item.ox_namespaces)
      @mods_item.find_by_terms_and_value(:location, :lib_repo)
    end
    it "should allow you to constrain your searches" do
      @mods_item.ng_xml.should_receive(:xpath).with('//oxns:location/oxns:physicalLocation[@authority="marcorg" and contains(., "NNC-RB")]', @mods_item.ox_namespaces)
      @mods_item.find_by_terms_and_value(:location,:lib_repo, "NNC-RB")
    end
    it "should allow you to use complex constraints" do
      @mods_item.ng_xml.should_receive(:xpath).with('//oxns:recordInfo/oxns:recordCreationDate[@encoding="w3cdtf" and contains(., "2010-07-12")]', @mods_item.ox_namespaces)
      @mods_item.find_by_terms_and_value(:record_info, :record_creation_date=>"2010-07-12")
    end
  end
  describe ".find_by_terms" do
    it "should find the right terms for title" do
      C = Cul::Scv::Hydra::Datastreams::ModsDocument
      T = C.terminology
      term = T.retrieve_term(:title)
      expect(term.xpath).to eql '//oxns:mods/oxns:titleInfo[not(@type)]/oxns:title'
      T.has_term?(:title).should be_true
      doc = @fixturemods.to_solr()
      title = doc["title_display_ssm"]
      expect(title).to eql ["The Manuscript, unidentified"]
    end


    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of term pointers and array/nodeset indexes" do
      @mods_item.find_by_terms( :access_condition ).length.should == 1
      @mods_item.find_by_terms( {:access_condition=>0} ).first.text.should == @mods_part.ng_xml.xpath('//oxns:accessCondition[@type="useAndReproduction"][1]', "oxns"=>"http://www.loc.gov/mods/v3").first.text
      Cul::Scv::Hydra::Datastreams::ModsDocument.terminology.xpath_with_indexes( :mods, {:main_title_info=>0}, :main_title ).should == '//oxns:mods/oxns:titleInfo[not(@type)][1]/oxns:title'
      # Nokogiri behaves unexpectedly
      #@mods_item.find_by_terms( {:title_info=>0}, :title ).length.should == 1
      @mods_item.find_by_terms(:title ).class.should == Nokogiri::XML::NodeSet
      @mods_item.find_by_terms(:title ).first.text.should == "Manuscript, unidentified"
    end
    it "should find a NodeSet where a terminology attribute has been set to :none" do
      @mods_item.find_by_terms(:location, :repo_text).first.text.should == "Rare Book and Manuscript Library, Columbia University"
    end

    it "should support xpath queries as the pointer" do
      @mods_item.find_by_terms('//oxns:relatedItem[@type="host"][1]//oxns:title[1]').first.text.should == "Project Facet Mapping\nTest"
    end

    it "should return nil if the xpath fails to generate" do
      pending "Can't decide if it's better to return nil or raise an error.  Choosing informative errors for now."
      @mods_item.find_by_terms( {:foo=>20}, :bar ).should == nil
    end
    it "should identify presence or absence of terms with shortcut methods" do
      @mock_inner.stub(:new_record?).and_return(true)
      built  = Cul::Scv::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Scv::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:title]=>'foo'})
      built.title?.should be_true
      built.clio?.should be_false
    end
  end
  describe ".xml_serialization" do
    it "should serialize new documents to xml" do
      @mock_inner.stub(:new_record?).and_return(true)
      Cul::Scv::Hydra::Datastreams::ModsDocument.new(@mock_inner,'descMetadata').to_xml
    end
    it "should parse and build namespaces identically" do
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.mods(:version=>"3.4",
           "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
           "xmlns"=>"http://www.loc.gov/mods/v3")
      end
      # namespaced attributes must be added after root node construction for namespace to be handled correctly
      builder.doc.root["xsi:schemaLocation"] = "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd"
      mods_ns = Nokogiri::XML::Document.parse(<<-src
<mods version='3.4'
      xmlns='http://www.loc.gov/mods/v3'
      xmlns:xlink='http://www.w3.org/1999/xlink'
      xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
      xsi:schemaLocation='http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-4.xsd'></mods>
src
)
      parsed = false
      mods_ns.root.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          parsed = node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      parsed.should be_true
      built = false
      builder.doc.root.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          built = node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      built.should be_true
      opts = { :element_order => false, :normalize_whitespace => true }
      passed = EquivalentXml.equivalent?(builder.doc, mods_ns, opts){ |n1, n2, result|
        unless result
        end
      }
      passed.should == true
    end
    it "should produce equivalent xml when built up programatically" do
      @mock_inner.stub(:new_record?).and_return(false)
      built = Cul::Scv::Hydra::Datastreams::ModsDocument.new(@mock_inner,'descMetadata')
      built.ng_xml = Cul::Scv::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:identifier] => "prd.custord.040148"})
      built.update_values({[:mods, :main_title_info, :non_sort] => "The "})
      built.update_values({[:mods, :main_title_info, :main_title] => "Manuscript, unidentified"})
      built.update_values({[:type_of_resource] => "text"})
      built.update_values({[:physical_description, :form_marc] => "electronic"})
      built.update_values({[:physical_description, :form_aat] => "books"})
      built.update_values({[:physical_description, :extent] => "4 item(s)"})
      built.update_values({[:physical_description, :reformatting_quality] => "access"})
      built.update_values({[:physical_description, :internet_media_type] => "image/tiff"})
      built.update_values({[:physical_description, :digital_origin] => "reformatted digital"})
      built.update_values({[:location, :lib_repo] => "NNC-RB"})
      built.update_values({[:location, :repo_text] => "Rare Book and Manuscript Library, Columbia University"})
      built.update_values({[:project, :project_title_info, :lib_project] => "Project Facet Mapping\nTest"})
      built.update_values({[:note] => "Original PRD customer order number: 040148"})
      built.update_values({[:access_condition] => "Columbia Libraries Staff Use Only."})
      built.update_values({[:record_info, :record_creation_date] => "2010-07-12"})
      built.update_values({[:language_code] => "eng"})
      built.update_values({[:record_info,:record_content_source]=> "NNC"})
      built.update_values({[:language,:language_term_text]=> "English"})
      built.update_values({[:language,:language_term_code]=> "eng"})
      built.update_values({[:record_info,:record_origin]=> <<ml
From PRD customer order database, edited to conform to the DLF Implementation Guidelines for Shareable MODS Records, Version 1.1.
ml
})
      opts = { :element_order => false, :normalize_whitespace => true }
      built.ng_xml.should be_equivalent_to(@mods_item.ng_xml)
    end
    it "should produce equivalent xml for recordInfo" do
      @mock_inner.stub(:new_record?).and_return(false)
      built = Cul::Scv::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Scv::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:record_info, :record_creation_date] => "2010-07-12"})
      built.update_values({[:record_info, :language_of_cataloging, :language_code] => "eng"})
      built.update_values({[:record_info,:record_content_source]=> "NNC"})
      built.update_values({[:record_info,:record_origin]=> <<ml
From PRD customer order database, edited to conform to the DLF Implementation Guidelines for Shareable MODS Records, Version 1.1.
ml
})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-record-info.xml")))
      built.ng_xml.should be_equivalent_to(parsed)
    end
    it "should produce equivalent xml for physical location" do
      @mock_inner.stub(:new_record?).and_return(false)
      built = Cul::Scv::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Scv::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:location, :lib_repo] => "NNC-RB"})
      built.update_values({[:location, :repo_text] => "Rare Book and Manuscript Library, Columbia University"})
      built.update_values({[:location, :shelf_locator] => "(Box no. \n        057)"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-physical-location.xml")))
      built.ng_xml.should be_equivalent_to(parsed)
    end
    it "should produce equivalent xml for date ranges" do
      @mock_inner.stub(:new_record?).and_return(false)
      built = Cul::Scv::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Scv::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:origin_info, :start_date]=>"1900"})
      built.update_values({[:origin_info, :end_date]=>"1905"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-date-range.xml")))
      #built.ng_xml.should be_equivalent_to(parsed)
      equivalent?(built.ng_xml,parsed)
    end
  end
  describe ".update_values" do
    it "should mark the datastream as dirty" do
      @mods_item.update_values({[:record_info,:record_content_source]=> "NNC"})
      @mods_item.changed?.should be_true
    end
  end
  describe ".to_solr" do
    it "should include nonSort text in display title and exclude it from index title" do
      solr_doc = @mods_item.to_solr
      solr_doc["title_display_ssm"].should include('The Manuscript, unidentified')
      solr_doc["title_si"].should == "Manuscript, unidentified"
    end
    it "should create the expected Solr hash for mapped project values" do
      solr_doc = @mods_item.to_solr
      # check the mapped facet value
      solr_doc["lib_project_sim"].should include("Successful Project Mapping")
      # check the unmapped display value
      solr_doc["lib_project_ssm"].should include("Project Facet Mapping Test")
      # check that the mapped value didn't find it's way into the display field
      solr_doc["lib_project_ssm"].should_not include("Successful Project Mapping")
      solr_doc["lib_repo_sim"].should include("RBML")
      # check the unmapped display value
      solr_doc["lib_repo_ssim"].should include("Rare Book and Manuscript Library")
      # check that the mapped value didn't find it's way into the display field
      solr_doc["lib_repo_ssim"].should_not include("RBML")


      puts 'ZZZZZZ: ' + solr_doc.inspect

      # location
      solr_doc["language_language_term_code_sim"].should == ['eng']
      solr_doc["language_language_term_text_sim"].should == ['English']

    end
  end
end
