require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Hydra::Datastreams::ModsDocument", type: :unit do

  let(:ds_fixture) { descMetadata(mock_inner, xml_fixture) }
  let(:ng_fixture) { Nokogiri::XML::Document.parse(xml_fixture) }

  let(:mock_ds) { double('datastream') }

  let(:mock_inner) do
    mock_inner = double('inner object')
    mock_inner.stub(:"new_record?").and_return(false)
    mock_inner.stub(:pid)
    mock_inner
  end

  let(:item_xml) { fixture( File.join("CUL_MODS", "mods-item.xml") ) }
  let(:part_xml) { fixture( File.join("CUL_MODS", "mods-part.xml") ) }

  let(:mods_part) { descMetadata(mock_inner, part_xml) }

  it "should automatically include the necessary modules" do
    Cul::Hydra::Datastreams::ModsDocument.included_modules.should include(OM::XML::Container)
    Cul::Hydra::Datastreams::ModsDocument.included_modules.should include(OM::XML::TermValueOperators)
    Cul::Hydra::Datastreams::ModsDocument.included_modules.should include(OM::XML::Validation)
  end

  describe ".ox_namespaces" do
    let(:xml_fixture) { item_xml }
    it "should merge terminology namespaces with document namespaces" do
      ds_fixture.ox_namespaces.should == {"oxns"=>"http://www.loc.gov/mods/v3", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns"=>"http://www.loc.gov/mods/v3"}
    end
    it "should correctly namespace attributes" do
      result = false
      ng_fixture.css('mods').first.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          result =  node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      result.should == true
    end
  end

  describe ".find_by_terms_and_value" do
    let(:xml_fixture) { item_xml }
    it "should use Nokogiri to retrieve a NodeSet corresponding to the term pointers" do
      ds_fixture.find_by_terms_and_value( :lib_project).length.should == 1
    end

    it "should allow you to search by term pointer" do
      ds_fixture.ng_xml.should_receive(:xpath).with('//oxns:location/oxns:physicalLocation[@authority="marcorg"]', ds_fixture.ox_namespaces)
      ds_fixture.find_by_terms_and_value(:location, :lib_repo)
    end
    it "should allow you to constrain your searches" do
      ds_fixture.ng_xml.should_receive(:xpath).with('//oxns:location/oxns:physicalLocation[@authority="marcorg" and contains(., "NNC-RB")]', ds_fixture.ox_namespaces)
      ds_fixture.find_by_terms_and_value(:location,:lib_repo, "NNC-RB")
    end
    it "should allow you to use complex constraints" do
      ds_fixture.ng_xml.should_receive(:xpath).with('//oxns:recordInfo/oxns:recordCreationDate[@encoding="w3cdtf" and contains(., "2010-07-12")]', ds_fixture.ox_namespaces)
      ds_fixture.find_by_terms_and_value(:record_info, :record_creation_date=>"2010-07-12")
    end
  end
  describe ".find_by_terms" do
    let(:xml_fixture) { item_xml }
    it "should find the right terms for title" do
      C = Cul::Hydra::Datastreams::ModsDocument
      T = C.terminology
      term = T.retrieve_term(:title)
      expect(term.xpath).to eql '//oxns:mods/oxns:titleInfo[not(@type)]/oxns:title'
      T.has_term?(:title).should be_truthy
      doc = ds_fixture.to_solr()
      title = doc["title_display_ssm"]
      expect(title).to eql ["The Manuscript, unidentified"]
    end

    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of term pointers and array/nodeset indexes" do
      ds_fixture.find_by_terms( :access_condition ).length.should == 1
      ds_fixture.find_by_terms( {:access_condition=>0} ).first.text.should == mods_part.ng_xml.xpath('//oxns:accessCondition[@type="useAndReproduction"][1]', "oxns"=>"http://www.loc.gov/mods/v3").first.text
      Cul::Hydra::Datastreams::ModsDocument.terminology.xpath_with_indexes( :mods, {:main_title_info=>0}, :main_title ).should == '//oxns:mods/oxns:titleInfo[not(@type)][1]/oxns:title'
      ds_fixture.find_by_terms(:title ).class.should == Nokogiri::XML::NodeSet
      ds_fixture.find_by_terms(:title ).first.text.should == "Manuscript, unidentified"
    end
    it "should find a NodeSet where a terminology attribute has been set to :none" do
      ds_fixture.find_by_terms(:location, :repo_text).first.text.should == "Rare Book and Manuscript Library, Columbia University"
    end

    it "should support xpath queries as the pointer" do
      ds_fixture.find_by_terms('//oxns:relatedItem[@type="host"][1]//oxns:title[1]').first.text.should == "Project Mapping\nTest"
    end

    it "should identify presence or absence of terms with shortcut methods" do
      mock_inner.stub(:new_record?).and_return(true)
      built  = Cul::Hydra::Datastreams::ModsDocument.new(mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:title]=>'foo'})
      built.title?.should be_truthy
      built.clio?.should be_falsey
    end
  end
end
