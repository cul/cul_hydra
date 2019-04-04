require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cul::Hydra::Solrizer::ModsFieldable, type: :unit do
  MODS_NS = {'mods'=>'http://www.loc.gov/mods/v3'}

  before(:all) do
    class ModsIndexDatastream
      include Cul::Hydra::Solrizer::ModsFieldable

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
      expect(@solr_doc).to include("title_si" => 'Manuscript, unidentified')
      # title_display_ssm is assigned in the ModsDocument OM selector
      expect(@solr_doc).to include("title_ssm" => ['The Manuscript, unidentified'])
    end

    it "should have normalized facet values" do
      @solr_doc["lib_collection_sim"].should == ['Collection Facet Normalization Test']
    end

    it "should facet on corporate and personal names, ignoring roleTerms" do
      @solr_doc["lib_name_sim"].should == ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745','Included Without Attribute']
      @solr_doc["lib_name_ssm"].should == ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745','Included Without Attribute']
    end

    it "should not include /mods/subject/name elements in the list of /mods/name elements" do
      @solr_doc["lib_name_sim"].should_not include('Jay, John, 1745-1829')
      @solr_doc["lib_name_ssm"].should_not include('Jay, John, 1745-1829')
    end

    it "should not include /mods/relatedItem/identifier[type='CLIO'] elements in the list of clio_identifier elements" do
      @solr_doc["clio_ssim"].should include('12381225')
      @solr_doc["clio_ssim"].should_not include('4080189')
    end

    it "should facet on the special library format values" do
      @solr_doc["lib_format_sim"].should == ['books']
    end
  end

  describe ".normalize" do
    it "should strip trailing and leading whitespace and normalize remaining space" do
      d = "   Foo \n Bar "
      e = "Foo Bar"
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d)
      a.should == e
    end

    it "should only strip punctuation when asked to" do
      d = "   'Foo \n Bar\" "
      e = "'Foo Bar\""
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d)
      a.should == e
      e = "Foo Bar\""
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d, true)
      a.should == e
      d = "<Jay, John (Pres. of Cong.)>"
      e = "Jay, John (Pres. of Cong.)"
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d, true)
      a.should == e

    end
  end

  describe '.role_text_to_solr_field_name' do
    let(:expected_values) do
      {
        'Author' => 'role_author_ssim',
        'Owner/Agent' => 'role_owner_agent_ssim',
        'Mixed case Role with Spaces' => 'role_mixed_case_role_with_spaces_ssim',
        'WAYYY      too much       space' => 'role_wayyy_too_much_space_ssim',
        '!! Adjacent Replaced Characters !!! collapsed into one' => 'role_adjacent_replaced_characters_collapsed_into_one_ssim'
      }
    end
    it "converts as expected" do
      expected_values.each do |role, expected_value|
        expect(described_class.role_text_to_solr_field_name(role)).to eq(expected_value)
      end
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
    it "should be able to translate a project title with periods in it" do
      @test_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-relateditem-project.xml")))
      @solr_doc = ModsIndexDatastream.new(@test_ng).to_solr
      @solr_doc["lib_project_short_ssim"].should == ["Lindquist Photographs"]
      @solr_doc["lib_project_full_ssim"].should == ["G.E.E. Lindquist Native American Photographs"]
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

  describe ".textual_dates" do
    before :all do
      @test_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-textual-dates-with-unusual-chars.xml")))
      @solr_doc = ModsIndexDatastream.new(@test_ng).to_solr
    end
    it "should not change the textual date, other than removing leading or trailing whitespace" do
      @solr_doc["lib_date_textual_ssm"].sort.should == ['-12 BCE', 'Circa 1940', '[19]22?']
    end
  end

  describe ".names" do
    before :all do
      @names_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-names.xml")))
    end
    it "should find name values and ignore roleTerms" do
      test = ModsIndexDatastream.new(@names_ng)
      test.names.should == ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745', 'Included Without Attribute', 'Dear Brother', 'Seminar 401']
    end
    it "should find name values with authority/role pairs" do
      test = ModsIndexDatastream.new(@names_ng)
      test.names(:marcrelator, 'rcp').should == ['Name, Recipient 1829-1745', 'Dear Brother']
    end
    it "should not find subject names" do
      test = ModsIndexDatastream.new(@names_ng)
      test.names.should_not include('Jay, John 1745-1829')
    end
  end

  describe ".add_names_by_text_role!" do
    before :all do
      @names_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-names.xml")))
    end
    it "should index names by role" do
      test = ModsIndexDatastream.new(@names_ng)
      doc = {}
      test.add_names_by_text_role!(doc)
      expect(doc).to include({
        'role_addressee_ssim' => ["Name, Recipient 1829-1745", "Dear Brother"],
        'role_owner_agent_ssim' => ["Name, Recipient 1829-1745"]
      })
    end
  end

  describe ".coordinates" do
    before :all do
      @subjects_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-subjects.xml")))
    end
    it "should find coordinate values" do
      test = ModsIndexDatastream.new(@subjects_ng)
      test.coordinates.should == ['40.8075, -73.9619', '40.6892, -74.0444', '-40.6892, 74.0444']
    end
  end

  describe ".classification_other" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-all.xml")))
    end
    it "should find classification values with authority 'z', meaning 'other'" do
      test = ModsIndexDatastream.new(@all_ng)
      test.classification_other.should == ['AB.CD.EF.G.123', 'AB.CD.EF.G.456']
    end
  end
  describe ".archive_org_identifier" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-all.xml")))
    end
    it "should index an archive.org identifier" do
      test = ModsIndexDatastream.new(@all_ng)
      test.archive_org_identifier.should == 'internet_archive_id_value'
    end
  end
  describe ".archival_context_json" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-archival-context.xml")))
    end
    let(:expected) { JSON.load(File.read(fixture( File.join("CUL_solr", "archival-context.json")))) }
    it "should produce json-ld for the archival context" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(expected[0]).to include_json(test.archival_context_json[0])
    end
    it "should add it to the solr document" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.to_solr).to have_key('archival_context_json_ss')
    end
  end
end
