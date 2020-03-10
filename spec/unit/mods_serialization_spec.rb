require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Hydra::Datastreams::ModsDocument", type: :unit do

  before(:all) do

  end

  before(:each) do
    @mock_inner = double('inner object')
    allow(@mock_inner).to receive(:"new_record?").and_return(false)
    @mock_repo = double('repository')
    @mock_ds = double('datastream')
    allow(@mock_repo).to receive(:config).and_return({})
    allow(@mock_repo).to receive(:datastream_profile).and_return({})
    allow(@mock_repo).to receive(:datastream_dissemination).and_return('My Content')
    allow(@mock_inner).to receive(:repository).and_return(@mock_repo)
    allow(@mock_inner).to receive(:pid)
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

  describe ".xml_serialization" do
    it "should serialize new documents to xml" do
      allow(@mock_inner).to receive(:"new_record?").and_return(true)
      Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner,'descMetadata').to_xml
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
      expect(parsed).to be true
      built = false
      builder.doc.root.attribute_nodes.each { |node|
        if node.name == 'schemaLocation'
          built = node.namespace.href == 'http://www.w3.org/2001/XMLSchema-instance'
        end
      }
      expect(built).to be true
      opts = { :element_order => false, :normalize_whitespace => true }
      passed = EquivalentXml.equivalent?(builder.doc, mods_ns, opts){ |n1, n2, result|
        unless result
        end
      }
      expect(passed).to be true
    end
    it "should produce equivalent xml when built up programatically" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner,'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:identifier] => "prd.custord.040148"})
      built.update_values({[:accession_number] => "GB0090"})
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
      built.update_values({[:project, :project_title_info, :lib_project] => "Project Mapping\nTest"})
      built.update_values({[:part, :part_title_info, :lib_part] => "Constituent item / part"})
      built.update_values({[:note] => "Original PRD customer order number: 040148"})
      built.update_values({[:access_condition] => "Columbia Libraries Staff Use Only."})
      built.update_values({[:record_info, :record_creation_date] => "2010-07-12"})
      built.update_values({[:language_code] => "eng"})
      built.update_values({[:record_info,:record_content_source]=> "NNC"})
      built.update_values({[:language,:language_term_text]=> "English"})
      built.update_values({[:language,:language_term_code]=> "eng"})
      built.update_values({[:origin_info,:date_created_start]=> "1801"})
      built.update_values({[:origin_info,:date_created_end]=> "1802"})
      built.update_values({[:subject,:topic]=> "Indians of North America--Missions"})
      built.update_values({[:subject,:geographic]=> "Rosebud Indian Reservation (S.D.)"})
      built.update_values({[:record_info,:record_origin]=> <<ml
From PRD customer order database, edited to conform to the DLF Implementation Guidelines for Shareable MODS Records, Version 1.1.
ml
})
      opts = { :element_order => false, :normalize_whitespace => true }
      expect(built.ng_xml).to be_equivalent_to(@mods_item.ng_xml)
    end
    it "should produce equivalent xml for recordInfo" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:record_info, :record_creation_date] => "2010-07-12"})
      built.update_values({[:record_info, :language_of_cataloging, :language_code] => "eng"})
      built.update_values({[:record_info,:record_content_source]=> "NNC"})
      built.update_values({[:record_info,:record_origin]=> <<ml
From PRD customer order database, edited to conform to the DLF Implementation Guidelines for Shareable MODS Records, Version 1.1.
ml
})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-record-info.xml")))
      expect(built.ng_xml).to be_equivalent_to(parsed)
    end
    it "should produce equivalent xml for physical location" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:location, :lib_repo] => "NNC-RB"})
      built.update_values({[:location, :repo_text] => "Rare Book and Manuscript Library, Columbia University"})
      built.update_values({[:location, :shelf_locator] => "(Box no.\n        057)"})
      built.update_values({[:location, :sublocation] => "exampleSublocation"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-physical-location.xml")))
      expect(built.ng_xml).to be_equivalent_to(parsed)
    end
    it "should produce equivalent xml for a single dateIssued value" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:origin_info, :date_issued]=>"1700"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-date-issued-single.xml")))
      expect(built.ng_xml).to be_equivalent_to(parsed)
      equivalent?(built.ng_xml,parsed)
    end
    it "should produce equivalent xml for a single dateCreated value" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:origin_info, :date_created]=>"1800"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-date-created-single.xml")))
      expect(built.ng_xml).to be_equivalent_to(parsed)
      equivalent?(built.ng_xml,parsed)
    end
    it "should produce equivalent xml for a single dateOther value" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:origin_info, :date_other]=>"1900"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-date-other-single.xml")))
      expect(built.ng_xml).to be_equivalent_to(parsed)
      equivalent?(built.ng_xml,parsed)
    end
    it "should produce equivalent xml for a dateIssued range" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:origin_info, :date_issued_start]=>"1701"})
      built.update_values({[:origin_info, :date_issued_end]=>"1702"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-date-issued-range.xml")))
      expect(built.ng_xml).to be_equivalent_to(parsed)
      equivalent?(built.ng_xml,parsed)
    end
    it "should produce equivalent xml for a dateCreated range" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:origin_info, :date_created_start]=>"1801"})
      built.update_values({[:origin_info, :date_created_end]=>"1802"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-date-created-range.xml")).read.gsub('iso8601','w3cdtf'))
      expect(built.ng_xml).to be_equivalent_to(parsed)
      equivalent?(built.ng_xml,parsed)
    end
    it "should produce equivalent xml for a dateOther range" do
      allow(@mock_inner).to receive(:"new_record?").and_return(false)
      built = Cul::Hydra::Datastreams::ModsDocument.new(@mock_inner, 'descMetadata')
      built.ng_xml = Cul::Hydra::Datastreams::ModsDocument.xml_template
      built.update_values({[:origin_info, :date_other_start]=>"1901"})
      built.update_values({[:origin_info, :date_other_end]=>"1902"})
      parsed = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-date-other-range.xml")))
      expect(built.ng_xml).to be_equivalent_to(parsed)
      equivalent?(built.ng_xml,parsed)
    end
  end
end
