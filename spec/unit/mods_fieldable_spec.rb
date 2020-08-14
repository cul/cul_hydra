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
    allow(@mock_repo).to receive(:config).and_return({})
    allow(@mock_repo).to receive(:datastream_profile).and_return({})
    allow(@mock_repo).to receive(:datastream).and_return('<datastreamProfile />')
    allow(@mock_repo).to receive(:datastream_dissemination).and_return('My Content')

    @mock_inner = double('inner object')
    allow(@mock_inner).to receive(:"new_record?").and_return(false)
    allow(@mock_inner).to receive(:repository).and_return(@mock_repo)
    allow(@mock_inner).to receive(:pid)
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
      expect(@solr_doc).to be_a Hash
    end

    it "should have a single sortable title" do
      expect(@solr_doc).to include("title_si" => 'MANUSCRIPT UNIDENTIFIED')
      # title_display_ssm is assigned in the ModsDocument OM selector
      expect(@solr_doc).to include("title_ssm" => ['The Manuscript, unidentified'])
    end

    it "should have normalized facet values" do
      expect(@solr_doc["lib_collection_sim"]).to eql ['Collection Facet Normalization Test']
    end

    it "should facet on corporate and personal names, ignoring roleTerms" do
      expect(@solr_doc["lib_name_sim"]).to eql ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745','Included Without Attribute']
      expect(@solr_doc["lib_name_sim"]).to eql ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745','Included Without Attribute']
    end

    it "should not include /mods/subject/name elements in the list of /mods/name elements" do
      expect(@solr_doc["lib_name_sim"]).not_to include('Jay, John, 1745-1829')
      expect(@solr_doc["lib_name_sim"]).not_to include('Jay, John, 1745-1829')
    end

    it "should not include /mods/relatedItem/identifier[type='CLIO'] elements in the list of clio_identifier elements" do
      expect(@solr_doc["clio_ssim"]).to include('12381225')
      expect(@solr_doc["clio_ssim"]).not_to include('4080189')
    end

    it "should facet on the special library format values" do
      expect(@solr_doc["lib_format_sim"]).to eql ['books']
    end
  end

  describe ".normalize" do
    it "should strip trailing and leading whitespace and normalize remaining space" do
      d = "   Foo \n Bar "
      e = "Foo Bar"
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d)
      expect(a).to eql e
    end

    it "should only strip punctuation when asked to" do
      d = "   'Foo \n Bar\" "
      e = "'Foo Bar\""
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d)
      expect(a).to eql e
      e = "Foo Bar\""
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d, true)
      expect(a).to eql e
      d = "<Jay, John (Pres. of Cong.)>"
      e = "Jay, John (Pres. of Cong.)"
      a = Cul::Hydra::Solrizer::ModsFieldable.normalize(d, true)
      expect(a).to eql e
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
      expect(test.main_title).to eql 'The Photographs'
    end
  end

  describe ".projects" do
    it "should find the project titles for faceting" do
      test = ModsIndexDatastream.new(@titles_ng)
      expect(test.projects).to eql ['Customer Order Project']
    end
    it "should be able to translate a project title with periods in it" do
      @test_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-relateditem-project.xml")))
      @solr_doc = ModsIndexDatastream.new(@test_ng).to_solr
      expect(@solr_doc["lib_project_short_ssim"]).to eql ["Lindquist Photographs"]
      expect(@solr_doc["lib_project_full_ssim"]).to eql ["G.E.E. Lindquist Native American Photographs"]
    end
  end

  describe ".collections" do
    it "should find the collection titles for faceting" do
      test = ModsIndexDatastream.new(@titles_ng)
      expect(test.collections).to eql ['The Pulitzer Prize Photographs']
    end
  end

  describe ".shelf_locators" do
    before :all do
      @test_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-physical-location.xml")))
      @solr_doc = ModsIndexDatastream.new(@test_ng).to_solr
    end
    it "should find the shelf locators" do
      expect(@solr_doc["lib_shelf_sim"]).to eql ["Box no. 057"]
    end
  end

  describe ".textual_dates" do
    before :all do
      @test_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-textual-dates-with-unusual-chars.xml")))
      @solr_doc = ModsIndexDatastream.new(@test_ng).to_solr
    end
    it "should not change the textual date, other than removing leading or trailing whitespace" do
      expect(@solr_doc["lib_date_textual_ssm"].sort).to eql ['-12 BCE', 'Circa 1940', '[19]22?']
    end
  end

  describe ".names" do
    before :all do
      @names_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-names.xml")))
    end
    it "should find name values and ignore roleTerms" do
      test = ModsIndexDatastream.new(@names_ng)
      expect(test.names).to eql ['Name, Inc.', 'Name, Personal 1745-1829', 'Name, Recipient 1829-1745', 'Included Without Attribute', 'Dear Brother', 'Seminar 401']
    end
    it "should find name values with authority/role pairs" do
      test = ModsIndexDatastream.new(@names_ng)
      expect(test.names(:marcrelator, 'rcp')).to eql ['Name, Recipient 1829-1745', 'Dear Brother']
    end
    it "should not find subject names" do
      test = ModsIndexDatastream.new(@names_ng)
      expect(test.names).not_to include('Jay, John 1745-1829')
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
      expect(test.coordinates).to eql ['40.8075, -73.9619', '40.6892, -74.0444', '-40.6892, 74.0444']
    end
  end

  describe ".classification_other" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-all.xml")))
    end
    it "should find classification values with authority 'z', meaning 'other'" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.classification_other).to eql ['AB.CD.EF.G.123', 'AB.CD.EF.G.456']
    end
  end
  describe ".archive_org_identifiers" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-all.xml")))
    end
    it "should index an archive.org identifier" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.archive_org_identifiers).to eql [
        { id: 'internet_archive_id_value', displayLabel: 'internet_archive_id_label' }
      ]
    end
  end
  describe ".archive_org_identifier" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-all.xml")))
    end
    it "should index an archive.org identifier" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.archive_org_identifier).to eql 'internet_archive_id_value'
    end
  end
  describe ".archival_context_json" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-archival-context.xml")))
    end
    let(:expected) { JSON.load(File.read(fixture( File.join("CUL_SOLR", "archival-context.json")))) }
    it "should produce json-ld for the archival context" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(expected[0]).to include_json(test.archival_context_json[0])
    end
    it "should add it to the solr document" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.to_solr).to have_key('archival_context_json_ss')
    end
  end
  describe ".copyright_statement" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-access-condition.xml")))
    end
    let(:expected) { 'http://rightsstatements.org/vocab/InC/1.0/' }
    it "should index a copyright statement" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.copyright_statement).to eql expected
      expect(test.to_solr['copyright_statement_ssi']).to eql expected
    end
  end
  describe ".reading_room_locations" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-site-fields.xml")))
    end
    let(:expected) { ['http://id.library.columbia.edu/term/45487bbd-97ef-44b4-9468-dda47594bc60'] }
    it "should index a copyright statement" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.reading_room_locations).to eql expected
      expect(test.to_solr['reading_room_ssim']).to eql expected
    end
  end
  describe ".search_scope" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-site-fields.xml")))
    end
    let(:expected) { 'project' }
    it "should index a copyright statement" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.search_scope).to eql [expected]
      expect(test.to_solr['search_scope_ssi']).to eql expected
    end
  end
  describe ".sort_title" do
    before :all do
      @all_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-titles-extended.xml")))
    end
    let(:expected) { 'GHOTOGRAPHS ゐ' }
    it "should index a sort title without diacritics, punctuation or case sensitivity" do
      test = ModsIndexDatastream.new(@all_ng)
      expect(test.to_solr['title_si']).to eql expected
    end
  end
end
