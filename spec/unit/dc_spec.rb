require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Scv::Hydra::Datastreams::DCMetadata" do
  
  before(:all) do
  end
  
  before(:each) do
    @fixture = Cul::Scv::Hydra::Datastreams::DCMetadata.from_xml( fixture( File.join("CUL_DC", "dc.xml") ) )
    @fixture.digital_object = @mock_inner
    @mock_inner = double('Rubydora::DigitalObject')
    @mock_repo = double('Rubydora::Repository')
    @mock_repo.stub(:config).and_return({})
    @mock_repo.stub(:datastream_dissemination=>'My Content')
    @mock_repo.stub(:datastream=>'My Datastream')
    @mock_inner.stub(:repository).and_return(@mock_repo)
    @mock_inner.stub(:pid).and_return('pid:do_not_use')
  end
  
  after(:all) do

  end
  
  it "should automatically include the necessary modules" do
    Cul::Scv::Hydra::Datastreams::DCMetadata.included_modules.should include(OM::XML::Container)
    Cul::Scv::Hydra::Datastreams::DCMetadata.included_modules.should include(OM::XML::TermValueOperators)
    Cul::Scv::Hydra::Datastreams::DCMetadata.included_modules.should include(OM::XML::Validation)
  end
  
  describe ".ox_namespaces" do
    it "should merge terminology namespaces with document namespaces" do
      @fixture.ox_namespaces.should == {
        "xmlns:oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:dc"=>"http://purl.org/dc/elements/1.1/"
      }
    end

    it "should correctly namespace attributes" do
      result = false
      @fixture.ng_xml.root.attribute_nodes.each { |node|
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
      @fixture.find_by_terms_and_value(:nobody_home).should == []
    end
    it "should use Nokogiri to retrieve a NodeSet corresponding to the term pointers" do
      @fixture.find_by_terms_and_value( :dc_title ).length.should == 1
    end

  end
  describe ".update_values" do
    it "should mark the datastream as dirty" do
      @fixture.update_values([:dc_title]=>"With Billy Burroughs, image")
      @fixture.changed?.should == true
    end
  end
  describe ".update_indexed_attributes" do
    it "should mark the datastream as dirty" do
      @fixture.update_indexed_attributes([:dc_type=>0]=>"UnlikelyType")
      @fixture.changed?.should == true
      @fixture.find_by_terms(:dc_type).first.text.should == "UnlikelyType"
    end
  end
  describe ".find_by_terms" do
    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of term pointers and array/nodeset indexes" do
      @fixture.find_by_terms(:dc_identifier).first.text.should == "prd.custord.070103a"
    end
    
    it "should support xpath queries as the pointer" do
      @fixture.find_by_terms('//dc:title').first.text.should == "With William Burroughs, image"
    end

    it "should be able to update or add values by pointer" do
      @fixture.update_values([:dc_title]=>"With Billy Burroughs, image")
      @fixture.find_by_terms(:dc_title).first.text.should == "With Billy Burroughs, image"
      puts "XPATH: " + Cul::Scv::Hydra::Datastreams::DCMetadata.terminology.retrieve_term(:dc_type).xpath_relative
      puts "TEMPLATE: " + Cul::Scv::Hydra::Datastreams::DCMetadata.terminology.retrieve_term(:dc_type).xml_builder_template
      @fixture.update_indexed_attributes([:dc_type=>0]=>"Text")
      puts @fixture.ng_xml.to_xml
      @fixture.find_by_terms(:dc_type).first.text.should == "Text"
    end
    
    it "should return nil if the xpath fails to generate" do
      pending "Can't decide if it's better to return nil or raise an error.  Choosing informative errors for now."
      @fixture.find_by_terms( {:foo=>20}, :bar ).should == nil
    end
    it "should identify presence or absence of terms with shortcut methods" do
      built  = Cul::Scv::Hydra::Datastreams::DCMetadata.from_xml(nil)
      built.update_values({[:dc_title]=>'foo'})
      built.dc_title?.should == true
      built.clio_id?.should == false
    end
  end
  describe ".xml_serialization" do
    it "should serialize new documents to xml" do
      @mock_inner.stub(:"new_record?").and_return(true)
      Cul::Scv::Hydra::Datastreams::DCMetadata.new(@mock_inner,'DC').to_xml
    end
    it "should parse and build namespaces identically" do
      doc = Cul::Scv::Hydra::Datastreams::DCMetadata.from_xml(nil).ng_xml
      # namespaced attributes must be added after root node construction for namespace to be handled correctly
      dc_ns = Nokogiri::XML::Document.parse(<<-src
<oai_dc:dc
      xmlns:oai_dc='http://www.openarchives.org/OAI/2.0/oai_dc/'
      xmlns:dc='http://purl.org/dc/elements/1.1/'
      xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
      xsi:schemaLocation='http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd'></oai_dc:dc>
src
)
      parsed = false
      dc_ns.root.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          parsed = node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      parsed.should == true
      built = false
      doc.root.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          built = node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      built.should == true
      puts doc.to_xml
      opts = { :element_order => false, :normalize_whitespace => true }
      passed = EquivalentXml.equivalent?(doc, dc_ns, opts){ |n1, n2, result|
        unless result
        end
      }
      passed.should == true
    end

    it "should produce equivalent xml when built up programatically" do
      @mock_inner.stub(:"new_record?").and_return(true)
      built = Cul::Scv::Hydra::Datastreams::DCMetadata.new(@mock_inner,'DC')
      built.update_values({[:dc_identifier] => "prd.custord.070103a"})
      built.update_values({[:dc_title] => "With William Burroughs, image"})
      built.update_values({[:dc_type] => "Collection"})
      opts = { :element_order => false, :normalize_whitespace => true }
      built.ng_xml.should be_equivalent_to(@fixture.ng_xml)
    end
  end

  describe ".to_solr" do
    it "should create the right map for Solr indexing" do
      @mock_inner.stub(:"new_record?").and_return(true)
      built = Cul::Scv::Hydra::Datastreams::DCMetadata.new(@mock_inner,'DC')
      built.update_values({[:dc_identifier] => "prd.custord.070103a"})
      built.update_values({[:dc_title] => "With William Burroughs, image"})
      built.update_values({[:dc_type] => "Collection"})
      built.ng_xml_doesnt_change!
      solr_doc = built.to_solr
      puts solr_doc.inspect
    end
  end
   
end
