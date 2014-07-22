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
end
