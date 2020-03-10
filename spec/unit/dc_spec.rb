require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Hydra::Datastreams::DCMetadata", type: :unit do
  
  before(:all) do
  end
  
  before(:each) do
    @fixture = Cul::Hydra::Datastreams::DCMetadata.from_xml( fixture( File.join("CUL_DC", "dc.xml") ) )
    @fixture.digital_object = @mock_inner
    @mock_inner = double('Rubydora::DigitalObject')
    @mock_repo = double('Rubydora::Repository')
    allow(@mock_repo).to receive(:config).and_return({})
    allow(@mock_repo).to receive(:datastream_dissemination).and_return('My Content')
    allow(@mock_repo).to receive(:datastream).and_return('My Datastream')
    allow(@mock_inner).to receive(:repository).and_return(@mock_repo)
    allow(@mock_inner).to receive(:pid).and_return('pid:do_not_use')
  end
  
  after(:all) do

  end
  
  it "should automatically include the necessary modules" do
    expect(Cul::Hydra::Datastreams::DCMetadata.included_modules).to include(OM::XML::Container)
    expect(Cul::Hydra::Datastreams::DCMetadata.included_modules).to include(OM::XML::TermValueOperators)
    expect(Cul::Hydra::Datastreams::DCMetadata.included_modules).to include(OM::XML::Validation)
  end
  
  describe ".ox_namespaces" do
    it "should merge terminology namespaces with document namespaces" do
      expect(@fixture.ox_namespaces).to eql( {
        "xmlns:oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/",
        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:dc"=>"http://purl.org/dc/elements/1.1/"
      })
    end

    it "should correctly namespace attributes" do
      result = false
      @fixture.ng_xml.root.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          result =  node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      expect(result).to be true
    end
  end
  
  
  describe ".find_by_terms_and_value" do
    it "should use Nokogiri to retrieve a NodeSet corresponding to the term pointers" do
      expect(@fixture.find_by_terms_and_value( :dc_title ).length).to eql 1
    end

  end
  describe ".update_values" do
    it "should mark the datastream as dirty" do
      @fixture.update_values([:dc_title]=>"With Billy Burroughs, image")
      expect(@fixture.changed?).to be true
    end
  end
  describe ".update_indexed_attributes" do
    it "should mark the datastream as dirty" do
      @fixture.update_indexed_attributes([:dc_type=>0]=>"UnlikelyType")
      expect(@fixture.changed?).to be true
      expect(@fixture.find_by_terms(:dc_type).first.text).to eql "UnlikelyType"
    end
  end
  describe ".find_by_terms" do
    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of term pointers and array/nodeset indexes" do
      expect(@fixture.find_by_terms(:dc_identifier).first.text).to eql "prd.custord.070103a"
    end
    
    it "should support xpath queries as the pointer" do
      expect(@fixture.find_by_terms('//dc:title').first.text).to eql "With William Burroughs, image"
    end

    it "should be able to update or add values by pointer" do
      @fixture.update_values([:dc_title]=>"With Billy Burroughs, image")
      expect(@fixture.find_by_terms(:dc_title).first.text).to eql "With Billy Burroughs, image"
      @fixture.update_indexed_attributes([:dc_type=>0]=>"Text")
      expect(@fixture.find_by_terms(:dc_type).first.text).to eql "Text"
    end
    
    it "should identify presence or absence of terms with shortcut methods" do
      built  = Cul::Hydra::Datastreams::DCMetadata.from_xml(nil)
      built.update_values({[:dc_title]=>'foo'})
      expect(built.dc_title?).to be true
      expect(built.clio_id?).to be false
    end
  end
  describe ".xml_serialization" do
    it "should serialize new documents to xml" do
      allow(@mock_inner).to receive(:"new_record?").and_return(true)
      Cul::Hydra::Datastreams::DCMetadata.new(@mock_inner,'DC').to_xml
    end
    it "should parse and build namespaces identically" do
      doc = Cul::Hydra::Datastreams::DCMetadata.from_xml(nil).ng_xml
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
      expect(parsed).to be true
      built = false
      doc.root.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          built = node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      expect(built).to be true
      opts = { :element_order => false, :normalize_whitespace => true }
      passed = EquivalentXml.equivalent?(doc, dc_ns, opts){ |n1, n2, result|
        unless result
        end
      }
      expect(passed).to be true
    end

    it "should produce equivalent xml when built up programatically" do
      allow(@mock_inner).to receive(:"new_record?").and_return(true)
      built = Cul::Hydra::Datastreams::DCMetadata.new(@mock_inner,'DC')
      built.update_values({[:dc_identifier] => "prd.custord.070103a"})
      built.update_values({[:dc_title] => "With William Burroughs, image"})
      built.update_values({[:dc_type] => "Collection"})
      opts = { :element_order => false, :normalize_whitespace => true }
      expect(built.ng_xml).to be_equivalent_to(@fixture.ng_xml)
    end
  end

  describe ".to_solr" do
    it "should create the right map for Solr indexing" do
      allow(@mock_inner).to receive(:"new_record?").and_return(true)
      built = Cul::Hydra::Datastreams::DCMetadata.new(@mock_inner,'DC')
      built.update_values({[:dc_identifier] => "prd.custord.070103a"})
      built.update_values({[:dc_title] => "With William Burroughs, image"})
      built.update_values({[:dc_type] => "Collection"})
      built.ng_xml_doesnt_change!
      solr_doc = built.to_solr
    end
  end
   
end
