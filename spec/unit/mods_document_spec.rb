require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cul::Hydra::Datastreams::ModsDocument, type: :unit do
  let(:terminology) { described_class.terminology }
  let(:ds_fixture) { descMetadata(mock_inner, xml_fixture) }
  let(:ng_fixture) { Nokogiri::XML::Document.parse(xml_fixture) }

  let(:mock_ds) { double('datastream') }

  let(:mock_inner) do
    mock_inner = double('inner object')
    allow(mock_inner).to receive(:"new_record?").and_return(false)
    allow(mock_inner).to receive(:pid)
    mock_inner
  end

  let(:item_xml) { fixture( File.join("CUL_MODS", "mods-item.xml") ) }
  let(:part_xml) { fixture( File.join("CUL_MODS", "mods-part.xml") ) }
  let(:genre_xml) { fixture( File.join("CUL_MODS", "mods-genre.xml") ) }

  let(:mods_part) { descMetadata(mock_inner, part_xml) }

  it "should automatically include the necessary modules" do
    expect(Cul::Hydra::Datastreams::ModsDocument.included_modules).to include(OM::XML::Container)
    expect(Cul::Hydra::Datastreams::ModsDocument.included_modules).to include(OM::XML::TermValueOperators)
    expect(Cul::Hydra::Datastreams::ModsDocument.included_modules).to include(OM::XML::Validation)
  end

  describe ".ox_namespaces" do
    let(:xml_fixture) { item_xml }
    it "should merge terminology namespaces with document namespaces" do
      expect(ds_fixture.ox_namespaces).to eql({"oxns"=>"http://www.loc.gov/mods/v3", "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", "xmlns"=>"http://www.loc.gov/mods/v3"})
    end
    it "should correctly namespace attributes" do
      result = false
      ng_fixture.css('mods').first.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          result =  node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      expect(result).to be true
    end
  end

  describe ".find_by_terms_and_value" do
    let(:xml_fixture) { item_xml }
    it "should use Nokogiri to retrieve a NodeSet corresponding to the term pointers" do
      expect(ds_fixture.find_by_terms_and_value( :lib_project).length).to eql 1
    end

    it "should allow you to search by term pointer" do
      expect(ds_fixture.ng_xml).to receive(:xpath).with('//oxns:location/oxns:physicalLocation[@authority="marcorg"]', ds_fixture.ox_namespaces)
      ds_fixture.find_by_terms_and_value(:location, :lib_repo)
    end
    it "should allow you to constrain your searches" do
      expect(ds_fixture.ng_xml).to receive(:xpath).with('//oxns:location/oxns:physicalLocation[@authority="marcorg" and contains(., "NNC-RB")]', ds_fixture.ox_namespaces)
      ds_fixture.find_by_terms_and_value(:location,:lib_repo, "NNC-RB")
    end
    it "should allow you to use complex constraints" do
      expect(ds_fixture.ng_xml).to receive(:xpath).with('//oxns:recordInfo/oxns:recordCreationDate[@encoding="w3cdtf" and contains(., "2010-07-12")]', ds_fixture.ox_namespaces)
      ds_fixture.find_by_terms_and_value(:record_info, :record_creation_date=>"2010-07-12")
    end
  end
  describe ".find_by_terms" do
    let(:xml_fixture) { item_xml }
    it "should find the right terms for title" do
      term = terminology.retrieve_term(:title)
      expect(term.xpath).to eql '//oxns:mods/oxns:titleInfo[not(@type)]/oxns:title'
      expect(terminology.has_term?(:title)).to be_truthy
      doc = ds_fixture.to_solr()
      title = doc["title_display_ssm"]
      expect(title).to eql ["The Manuscript, unidentified"]
    end
    context "for genre" do
      let(:xml_fixture) { genre_xml }
      it "should find the right terms for genre" do
        term = terminology.retrieve_term(:lib_genre)
        expect(term.xpath).to eql '//oxns:mods/oxns:genre[@authority]'
        expect(terminology.has_term?(:lib_genre)).to be_truthy
        doc = ds_fixture.to_solr()
        genre = doc["lib_genre_ssim"]
        expect(genre).to eql ["Records (Documents)"]
      end
    end
    it "should use Nokogiri to retrieve a NodeSet corresponding to the combination of term pointers and array/nodeset indexes" do
      expect(ds_fixture.find_by_terms( :access_condition ).length).to eql  1
      expect(ds_fixture.find_by_terms( {:access_condition=>0} ).first.text).to eql  mods_part.ng_xml.xpath('//oxns:accessCondition[@type="useAndReproduction"][1]', "oxns"=>"http://www.loc.gov/mods/v3").first.text
      expect(terminology.xpath_with_indexes( :mods, {:main_title_info=>0}, :main_title )).to eql  '//oxns:mods/oxns:titleInfo[not(@type)][1]/oxns:title'
      expect(ds_fixture.find_by_terms(:title ).class).to eql  Nokogiri::XML::NodeSet
      expect(ds_fixture.find_by_terms(:title ).first.text).to eql  "Manuscript, unidentified"
    end
    it "should find a NodeSet where a terminology attribute has been set to :none" do
      expect(ds_fixture.find_by_terms(:location, :repo_text).first.text).to eql "Rare Book and Manuscript Library, Columbia University"
    end

    it "should support xpath queries as the pointer" do
      expect(ds_fixture.find_by_terms('//oxns:relatedItem[@type="host"][1]//oxns:title[1]').first.text).to eql "Project Mapping\nTest"
    end

    it "should identify presence or absence of terms with shortcut methods" do
      allow(mock_inner).to receive(:new_record?).and_return(true)
      built  = described_class.new(mock_inner, 'descMetadata')
      built.ng_xml = described_class.xml_template
      built.update_values({[:title]=>'foo'})
      expect(built.title?).to be_truthy
      expect(built.clio?).to be_falsey
    end
  end
end
