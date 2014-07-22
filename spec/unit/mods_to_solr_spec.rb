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
    @fixturemods = descMetadata(@mock_inner, fixture( File.join("CUL_MODS", "mods-item.xml")))
    item_xml = fixture( File.join("CUL_MODS", "mods-item.xml"))
    @mods_item = descMetadata(@mock_inner, item_xml)
    @mods_ng = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-item.xml")))
    @mods_ns = Nokogiri::XML::Document.parse(fixture( File.join("CUL_MODS", "mods-ns.xml")))
    part_xml = fixture( File.join("CUL_MODS", "mods-part.xml"))
    @mods_part = descMetadata(@mock_inner, part_xml)
    @mods_all = descMetadata(@mock_inner, fixture( File.join("CUL_MODS", "mods-all.xml")))
  end

  after(:all) do

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
      solr_doc["lib_project_sim"].should include("Successful Project Mapping") # We're not doing project mapping anymore
      # check the unmapped display value
      solr_doc["lib_project_ssm"].should include("Project Facet Mapping Test")
      # check that the mapped value didn't find it's way into the display field
      solr_doc["lib_project_ssm"].should_not include("Successful Project Mapping")
      solr_doc["lib_repo_sim"].should include("RBML") # We're not doing repo mapping anymore
      # check the unmapped display value
      solr_doc["lib_repo_ssim"].should include("Rare Book and Manuscript Library")
      # check that the mapped value didn't find it's way into the display field
      solr_doc["lib_repo_ssim"].should_not include("RBML")
      # check the language term code and text fields
      solr_doc["language_language_term_code_sim"].should == ['eng']
      solr_doc["language_language_term_text_sim"].should == ['English']
      # check the date fields
      solr_doc["origin_info_date_created_start_ssm"].should == ['1801']
      solr_doc["origin_info_date_created_end_ssm"].should == ['1802']
      # check specially generated start_date and end_date fields
      #solr_doc["lib_start_date_ss"].should == '1801'
      #solr_doc["lib_start_date_year_ssi"].should == '1801'
      #solr_doc["lib_end_date_ss"].should == '1802'
      #solr_doc["lib_end_date_year_ssi"].should == '1802'
      solr_doc["lib_start_date_year_itsi"].should == 1801
      solr_doc["lib_end_date_year_itsi"].should == 1802
      solr_doc["lib_date_year_range_si"].should == '1801-1802'
      solr_doc["subject_topic_sim"].should == ['Indians of North America--Missions']
      solr_doc["subject_geographic_sim"].should == ['Rosebud Indian Reservation (S.D.)']
      text = solr_doc["all_text_teim"].join(' ')
      text.should include("Indians of North America")
      text.should include("Rosebud Indian Reservation")
    end
    describe "date element handling" do
      it "handles date issued single" do
        item_xml = fixture( File.join("CUL_MODS", "mods-date-issued-single.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["origin_info_date_issued_ssm"].should == ['1700']
        solr_doc["origin_info_date_issued_start_ssm"].should == nil
        solr_doc["origin_info_date_issued_end_ssm"].should == nil
        solr_doc["all_text_teim"].join(' ').should include("1700")
        #solr_doc["lib_start_date_ss"].should == '1700'
        #solr_doc["lib_start_date_year_ssi"].should == '1700'
        #solr_doc["lib_end_date_ss"].should == '1700'
        #solr_doc["lib_end_date_year_ssi"].should == '1700'
        solr_doc["lib_start_date_year_itsi"].should == 1700
        solr_doc["lib_end_date_year_itsi"].should == 1700
        solr_doc["lib_date_year_range_si"].should == '1700-1700'
      end
      it "handles date issued range" do
        item_xml = fixture( File.join("CUL_MODS", "mods-date-issued-range.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["origin_info_date_issued_ssm"].should == ['1701']
        solr_doc["origin_info_date_issued_start_ssm"].should == ['1701']
        solr_doc["origin_info_date_issued_end_ssm"].should == ['1702']
        #solr_doc["lib_start_date_ss"].should == '1701'
        #solr_doc["lib_start_date_year_ssi"].should == '1701'
        #solr_doc["lib_end_date_ss"].should == '1702'
        #solr_doc["lib_end_date_year_ssi"].should == '1702'
        solr_doc["lib_start_date_year_itsi"].should == 1701
        solr_doc["lib_end_date_year_itsi"].should == 1702
        solr_doc["lib_date_year_range_si"].should == '1701-1702'
      end
      it "handles date created single" do
        item_xml = fixture( File.join("CUL_MODS", "mods-date-created-single.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["origin_info_date_created_ssm"].should == ['1800']
        solr_doc["origin_info_date_created_start_ssm"].should == nil
        solr_doc["origin_info_date_created_end_ssm"].should == nil
        #solr_doc["lib_start_date_ss"].should == '1800'
        #solr_doc["lib_start_date_year_ssi"].should == '1800'
        #solr_doc["lib_end_date_ss"].should == '1800'
        #solr_doc["lib_end_date_year_ssi"].should == '1800'
        solr_doc["lib_start_date_year_itsi"].should == 1800
        solr_doc["lib_end_date_year_itsi"].should == 1800
        solr_doc["lib_date_year_range_si"].should == '1800-1800'
      end
      it "handles date created range" do
        item_xml = fixture( File.join("CUL_MODS", "mods-date-created-range.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["origin_info_date_created_ssm"].should == ['1801']
        solr_doc["origin_info_date_created_start_ssm"].should == ['1801']
        solr_doc["origin_info_date_created_end_ssm"].should == ['1802']
        #solr_doc["lib_start_date_ss"].should == '1801'
        #solr_doc["lib_start_date_year_ssi"].should == '1801'
        #solr_doc["lib_end_date_ss"].should == '1802'
        #solr_doc["lib_end_date_year_ssi"].should == '1802'
        solr_doc["lib_start_date_year_itsi"].should == 1801
        solr_doc["lib_end_date_year_itsi"].should == 1802
        solr_doc["lib_date_year_range_si"].should == '1801-1802'
      end
      it "handles date other single" do
        item_xml = fixture( File.join("CUL_MODS", "mods-date-other-single.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["origin_info_date_other_ssm"].should == ['1900']
        solr_doc["origin_info_date_other_start_ssm"].should == nil
        solr_doc["origin_info_date_other_end_ssm"].should == nil
        #solr_doc["lib_start_date_ss"].should == '1900'
        #solr_doc["lib_start_date_year_ssi"].should == '1900'
        #solr_doc["lib_end_date_ss"].should == '1900'
        #solr_doc["lib_end_date_year_ssi"].should == '1900'
        solr_doc["lib_start_date_year_itsi"].should == 1900
        solr_doc["lib_end_date_year_itsi"].should == 1900
        solr_doc["lib_date_year_range_si"].should == '1900-1900'
      end
      it "handles date other range" do
        item_xml = fixture( File.join("CUL_MODS", "mods-date-other-range.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["origin_info_date_other_ssm"].should == ['1901']
        solr_doc["origin_info_date_other_start_ssm"].should == ['1901']
        solr_doc["origin_info_date_other_end_ssm"].should == ['1902']
        #solr_doc["lib_start_date_ss"].should == '1901'
        #solr_doc["lib_start_date_year_ssi"].should == '1901'
        #solr_doc["lib_end_date_ss"].should == '1902'
        #solr_doc["lib_end_date_year_ssi"].should == '1902'
        solr_doc["lib_start_date_year_itsi"].should == 1901
        solr_doc["lib_end_date_year_itsi"].should == 1902
        solr_doc["lib_date_year_range_si"].should == '1901-1902'
      end
      it "handles date years that are fewer than four characters long, whether positive (CE) or negative (BCE)" do
        item_xml = fixture( File.join("CUL_MODS", "mods-date-range-short-years.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["origin_info_date_other_ssm"].should == ['-99']
        solr_doc["origin_info_date_other_start_ssm"].should == ['-99']
        solr_doc["origin_info_date_other_end_ssm"].should == ['25']
        #solr_doc["lib_start_date_ss"].should == '-99'
        #solr_doc["lib_start_date_year_ssi"].should == '-0099'
        #solr_doc["lib_end_date_ss"].should == '25'
        #solr_doc["lib_end_date_year_ssi"].should == '0025'
        solr_doc["lib_start_date_year_itsi"].should == -99
        solr_doc["lib_end_date_year_itsi"].should == 25
        solr_doc["lib_date_year_range_si"].should == '-0099-0025'
        #solr_doc["lib_start_date_year_dttsi"] = '-0099-01-01T00:00:00Z'
        #solr_doc["lib_end_date_year_dttsi"] = '0025-01-01T00:00:00Z'
      end
    end
    describe "location" do
      describe "physicalLocation" do
        it "should be in text field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("all_text_teim")
          # check the mapped facet value
          solr_doc["all_text_teim"].join(' ').should include("RBML") # We're not doing repo mapping anymore
          # check the unmapped display value
          solr_doc["all_text_teim"].join(' ').should include("Rare Book and Manuscript Library")
        end
      end
      describe "sublocation" do
        it "should be in text field" do
          item_xml = fixture( File.join("CUL_MODS", "mods-physical-location.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("exampleSublocation")
        end
      end
      describe "shelfLocator" do
        it "should be in text field" do
          item_xml = fixture( File.join("CUL_MODS", "mods-physical-location.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("(Box no. 057)")
        end
      end
    end
    describe "name" do
      describe "namePart" do
        it "should be in text field" do
          solr_doc = @mods_all.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("Name, Recipient")
        end
      end
    end
    describe "relatedItem" do
      describe "[@type='Host, @displayLabel='Project']" do
        it "should be in facet field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("lib_project_sim")
          solr_doc["lib_project_sim"].should include("Successful Project Mapping")
        end
        it "should be in text field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("Project Facet Mapping Test")
          solr_doc["all_text_teim"].join(' ').should include("Successful Project Mapping")
        end
      end
    end
    describe "relatedItem" do
      describe "[@type='Host, @displayLabel='Collection']" do
        it "should be in facet field" do
          solr_doc = @mods_all.to_solr
          solr_doc.should include("lib_collection_sim")
          solr_doc["lib_collection_sim"].should include("Collection Facet Normalization Test")
          solr_doc["all_text_teim"].join(' ').should include("Collection Facet Normalization Test")
        end
        it "should be in text field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("Project Facet Mapping Test")
          solr_doc["all_text_teim"].join(' ').should include("Successful Project Mapping")
        end
      end
    end
    describe "physicalDescription" do
      describe "form" do
        it "should be in facet field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("lib_format_sim")
          solr_doc["lib_format_sim"].should include("books")
        end
        it "should be in text field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("books")
        end
      end
    end
    describe "language" do
      describe "languageTerm" do
        it "code should be faceted and texted" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("language_language_term_code_sim")
          solr_doc["language_language_term_code_sim"].should include("eng")
          solr_doc["all_text_teim"].join(' ').should include(" eng")
        end
        it "text should be faceted and texted" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("language_language_term_text_sim")
          solr_doc["language_language_term_text_sim"].should include("English")
          solr_doc["all_text_teim"].join(' ').should include("English")
        end
      end
    end
    describe "note" do
      it "should be texted" do
        item_xml = fixture( File.join("CUL_MODS", "mods-001.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
          solr_doc["all_text_teim"].join(' ').should include("Original PRD customer order number")
      end
    end
    describe "title" do
      describe "main" do
        it "should have the expected main title" do
          item_xml = fixture( File.join("CUL_MODS", "mods-titles.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc["title_si"].should include("Photographs")
        end
        it "should text all the titles" do
          item_xml = fixture( File.join("CUL_MODS", "mods-titles.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc["all_text_teim"].join(' ').should include("Fotos")
        end
      end
    end
  end
end
