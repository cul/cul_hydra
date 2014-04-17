require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cul::Scv::Hydra::Solrizer::ScvModsFieldable do
  MODS_NS = {'mods'=>'http://www.loc.gov/mods/v3'}

  before(:all) do
    class ModsIndexDatastream
      include Cul::Scv::Hydra::Solrizer::ScvModsFieldable
      map_field("lib_repo_sim", :marc_to_facet)
      map_field("lib_repo_ssm", :marc_to_display)
      map_field("lib_project_sim", :project_to_facet)

      attr_accessor :ng_xml
      def initialize(ng_xml)
        self.ng_xml= ng_xml
      end
    end
  end
  
  before(:each) do
    @mock_repo = double('repository')
    @mock_ds = double('datastream')
    @mock_repo.stub(:config).and_return({})
    @mock_repo.stub(:datastream_profile).and_return({})
    @mock_repo.stub(:datastream).and_return('<datastreamProfile />')
    @mock_repo.stub(:datastream_dissemination=>'My Content')

    @mock_inner = double('inner object')
    @mock_inner.stub(:"new_record?").and_return(false)
    @mock_inner.stub(:repository).and_return(@mock_repo)
    @mock_inner.stub(:pid)
    @item_xml = fixture( File.join("CUL_MODS", "mods-item.xml") ).read
    @item_om = descMetadata(@mock_inner, @item_xml)

    @item_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-item.xml")))
    @mods_ns = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-ns.xml")))
    @part_xml = fixture( File.join("CUL_MODS", "mods-part.xml") )
    @part_om = descMetadata(@mock_inner, @part_xml)
    @titles_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-titles.xml")))
  end
  
  after(:all) do

  end

  describe ".to_solr" do
    before :all do
      @test_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-all.xml")))
      @solr_doc = ModsIndexDatastream.new(@test_ng).to_solr
    end

    it "should produce a hash" do
      @solr_doc.should be_a Hash 
    end

    it "should have a single sortable title" do
      @solr_doc["title_si"] = 'Manuscript, Unidentified'
      @solr_doc["title_display_ssm"] = ['The Manuscript, Unidentified']
    end

    it "should have normalized facet values" do
      @solr_doc["lib_collection_sim"].should == ['Collection Facet Normalization Test']
    end

    it "should have value-mapped project facets" do
      @solr_doc["lib_project_sim"].should == ['Successful Project Mapping']
    end

    it "should facet on corporate and personal names, ignoring roleTerms" do
      @solr_doc["lib_name_sim"].should == ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745']
      @solr_doc["lib_name_ssm"].should == ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745']
    end

    it "should facet on the special library format values" do
      @solr_doc["lib_format_sim"].should == ['books']
    end

    it "should have value-mapped repo facets" do
      @solr_doc["lib_repo_sim"].should == ['RBML']
    end
  end

  describe ".normalize" do
    it "should strip trailing and leading whitespace and normalize remaining space" do
      d = "   Foo \n Bar "
      e = "Foo Bar"
      a = Cul::Scv::Hydra::Solrizer::ScvModsFieldable.normalize(d)
      a.should == e
    end

    it "should only strip punctuation when asked to" do
      d = "   'Foo \n Bar\" "
      e = "'Foo Bar\""
      a = Cul::Scv::Hydra::Solrizer::ScvModsFieldable.normalize(d)
      a.should == e
      e = "Foo Bar\""
      a = Cul::Scv::Hydra::Solrizer::ScvModsFieldable.normalize(d, true)
      a.should == e
      d = "<Jay, John (Pres. of Cong.)>"
      e = "Jay, John (Pres. of Cong.)"
      a = Cul::Scv::Hydra::Solrizer::ScvModsFieldable.normalize(d, true)
      a.should == e

    end
  end

  describe ".main_title" do
    it "should find the top-level titles" do
      test = ModsIndexDatastream.new(@titles_ng)
      test.main_title.should == 'The Photographs'
    end
  end

  describe ".projects" do
    it "should find the project titles for faceting" do
      test = ModsIndexDatastream.new(@titles_ng)
      test.projects.should == ['Customer Order Project']
    end
  end

  describe ".collections" do
    it "should find the collection titles for faceting" do
      test = ModsIndexDatastream.new(@titles_ng)
      test.collections.should == ['The Pulitzer Prize Photographs']
    end
  end

  describe ".shelf_locators" do
    before :all do
      @test_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-physical-location.xml")))
      @solr_doc = ModsIndexDatastream.new(@test_ng).to_solr
    end
    it "should find the shelf locators" do
      @solr_doc["lib_shelf_sim"].should == ["Box no. 057"]
    end
  end

  describe ".names" do
    before :all do
      @names_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-names.xml")))
    end
    it "should find name values and ignore roleTerms" do
      test = ModsIndexDatastream.new(@names_ng)
      test.names.should == ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745', 'Dear Brother', 'Jay, John 1745-1829']
    end
    it "should find name values with authority/role pairs" do
      test = ModsIndexDatastream.new(@names_ng)
      test.names(:marcrelator, 'rcp').should == ['Name, Recipient 1829-1745', 'Dear Brother'] 
    end
  end
end