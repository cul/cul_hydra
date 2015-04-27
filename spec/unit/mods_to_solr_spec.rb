require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Hydra::Datastreams::ModsDocument", type: :unit do

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
    it "should return early if the descMetadata content does not actually contain a mods element, avoiding raised NoMethodError from future method lines" do
      non_mods_item = descMetadata(@mock_inner, fixture( File.join("CUL_DC", "dc.xml")))
      solr_doc = non_mods_item.to_solr
      solr_doc.should == {}
    end
    it "should include nonSort text in display title and exclude it from index title" do
      solr_doc = @mods_item.to_solr
      solr_doc["title_display_ssm"].should include('The Manuscript, unidentified')
      solr_doc["title_si"].should == "Manuscript, unidentified"
    end
    it "should create the expected Solr hash for mapped project values" do
      solr_doc = @mods_item.to_solr
      # check the mapped facet value
      solr_doc["lib_project_short_ssim"].should include("Successful Project Mapping For Short Project Title")
      solr_doc["lib_project_full_ssim"].should include("Successful Project Mapping For Full Project Title")
      # check that various repo mappings are working
      solr_doc["lib_repo_short_ssim"].should include("Rare Book & Manuscript Library")
      solr_doc["lib_repo_long_sim"].should include("Rare Book & Manuscript Library")
      solr_doc["lib_repo_full_ssim"].should include("Rare Book & Manuscript Library, Columbia University")
      # check the language term code and text fields
      solr_doc["language_language_term_code_ssim"].should == ['eng']
      solr_doc["language_language_term_text_ssim"].should == ['English']
      # check the date fields
      solr_doc["origin_info_date_created_start_ssm"].should == ['1801']
      solr_doc["origin_info_date_created_end_ssm"].should == ['1802']
      # check specially generated start_date and end_date fields
      solr_doc["lib_start_date_year_itsi"].should == 1801
      solr_doc["lib_end_date_year_itsi"].should == 1802
      solr_doc["lib_date_year_range_si"].should == '1801-1802'
      solr_doc["lib_date_textual_ssm"].should == ['Between 1801 and 1802'] # Derived from key date
      solr_doc["subject_topic_sim"].should == ['Indians of North America--Missions']
      solr_doc["subject_geographic_sim"].should == ['Rosebud Indian Reservation (S.D.)']
      text = solr_doc["all_text_teim"].join(' ')
      text.should include("Indians of North America")
      text.should include("Rosebud Indian Reservation")
    end
    describe "originInfo" do
      describe "date element handling" do
        it "handles date issued single" do
          item_xml = fixture( File.join("CUL_MODS", "mods-date-issued-single.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr

          solr_doc["origin_info_date_issued_ssm"].should == ['1700']
          solr_doc["origin_info_date_issued_start_ssm"].should == nil
          solr_doc["origin_info_date_issued_end_ssm"].should == nil
          solr_doc["all_text_teim"].join(' ').should include("1700")
          solr_doc["lib_start_date_year_itsi"].should == 1700
          solr_doc["lib_end_date_year_itsi"].should == 1700
          solr_doc["lib_date_year_range_si"].should == '1700-1700'
          solr_doc["lib_date_textual_ssm"].should == ['1700'] # Derived from key date
        end
        it "handles date issued range" do
          item_xml = fixture( File.join("CUL_MODS", "mods-date-issued-range.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr

          solr_doc["origin_info_date_issued_ssm"].should == ['1701']
          solr_doc["origin_info_date_issued_start_ssm"].should == ['1701']
          solr_doc["origin_info_date_issued_end_ssm"].should == ['1702']
          solr_doc["lib_start_date_year_itsi"].should == 1701
          solr_doc["lib_end_date_year_itsi"].should == 1702
          solr_doc["lib_date_year_range_si"].should == '1701-1702'
          solr_doc["lib_date_textual_ssm"].should == ['Between 1701 and 1702'] # Derived from key date
        end
        it "handles date created single" do
          item_xml = fixture( File.join("CUL_MODS", "mods-date-created-single.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr

          solr_doc["origin_info_date_created_ssm"].should == ['1800']
          solr_doc["origin_info_date_created_start_ssm"].should == nil
          solr_doc["origin_info_date_created_end_ssm"].should == nil
          solr_doc["lib_start_date_year_itsi"].should == 1800
          solr_doc["lib_end_date_year_itsi"].should == 1800
          solr_doc["lib_date_year_range_si"].should == '1800-1800'
          solr_doc["lib_date_textual_ssm"].should == ['1800'] # Derived from key date
        end
        it "handles date created range" do
          item_xml = fixture( File.join("CUL_MODS", "mods-date-created-range.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr

          solr_doc["origin_info_date_created_ssm"].should == ['1801']
          solr_doc["origin_info_date_created_start_ssm"].should == ['1801']
          solr_doc["origin_info_date_created_end_ssm"].should == ['1802']
          solr_doc["lib_start_date_year_itsi"].should == 1801
          solr_doc["lib_end_date_year_itsi"].should == 1802
          solr_doc["lib_date_year_range_si"].should == '1801-1802'
          solr_doc["lib_date_textual_ssm"].should == ['Between 1801 and 1802'] # Derived from key date
        end
        it "handles date other single" do
          item_xml = fixture( File.join("CUL_MODS", "mods-date-other-single.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr

          solr_doc["origin_info_date_other_ssm"].should == ['1900']
          solr_doc["origin_info_date_other_start_ssm"].should == nil
          solr_doc["origin_info_date_other_end_ssm"].should == nil
          solr_doc["lib_start_date_year_itsi"].should == 1900
          solr_doc["lib_end_date_year_itsi"].should == 1900
          solr_doc["lib_date_year_range_si"].should == '1900-1900'
          solr_doc["lib_date_textual_ssm"].should == ['1900'] # Derived from key date
        end
        it "handles date other range" do
          item_xml = fixture( File.join("CUL_MODS", "mods-date-other-range.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr

          solr_doc["origin_info_date_other_ssm"].should == ['1901']
          solr_doc["origin_info_date_other_start_ssm"].should == ['1901']
          solr_doc["origin_info_date_other_end_ssm"].should == ['1902']
          solr_doc["lib_start_date_year_itsi"].should == 1901
          solr_doc["lib_end_date_year_itsi"].should == 1902
          solr_doc["lib_date_year_range_si"].should == '1901-1902'
          solr_doc["lib_date_textual_ssm"].should == ['Between 1901 and 1902'] # Derived from key date
        end
        it "handles date years that are fewer than four characters long, whether positive (CE) or negative (BCE)" do
          item_xml = fixture( File.join("CUL_MODS", "mods-date-range-short-years.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr

          solr_doc["origin_info_date_other_ssm"].should == ['-99']
          solr_doc["origin_info_date_other_start_ssm"].should == ['-99']
          solr_doc["origin_info_date_other_end_ssm"].should == ['25']
          solr_doc["lib_start_date_year_itsi"].should == -99
          solr_doc["lib_end_date_year_itsi"].should == 25
          solr_doc["lib_date_year_range_si"].should == '-0099-0025'
          solr_doc["lib_date_textual_ssm"].should == ['Between 99 BCE and 25 CE'] # Derived from key date
        end
        describe "lib_date_year_range_si generation for years with 'u' characters" do
          it "replaces 'u' characters with zeroes when they're part of, but not all of, a year's digits" do
            item_xml = fixture( File.join("CUL_MODS", "mods-dates-with-some-u-characters.xml") )
            mods_item = descMetadata(@mock_inner, item_xml)
            solr_doc = mods_item.to_solr
            solr_doc["lib_date_year_range_si"].should == '1870-1900'
          end
          it "uses only the start date when an end date is all 'u' characters" do
            item_xml = fixture( File.join("CUL_MODS", "mods-date-end-with-all-u-characters.xml") )
            mods_item = descMetadata(@mock_inner, item_xml)
            solr_doc = mods_item.to_solr
            solr_doc["lib_date_year_range_si"].should == '1870-1870'
          end
          it "uses only the end date when a start date is all 'u' characters" do
            item_xml = fixture( File.join("CUL_MODS", "mods-date-start-with-all-u-characters.xml") )
            mods_item = descMetadata(@mock_inner, item_xml)
            solr_doc = mods_item.to_solr
            solr_doc["lib_date_year_range_si"].should == '1920-1920'
          end
          it "doesn't populate the lib_date_year_range_si field when both the start and end dates are all 'u' characters" do
            item_xml = fixture( File.join("CUL_MODS", "mods-dates-with-all-u-characters.xml") )
            mods_item = descMetadata(@mock_inner, item_xml)
            solr_doc = mods_item.to_solr
            solr_doc["lib_date_year_range_si"].should == nil
          end
        end
        it "extracts tetual dates (non-key dates)" do
          item_xml = fixture( File.join("CUL_MODS", "mods-textual-date.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc["lib_date_textual_ssm"].should == ['Some time around 1919']
        end
      end
      describe "publisher" do
        it "should be stored as a string" do
          item_xml = fixture( File.join("CUL_MODS", "mods-origin-info.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("origin_info_publisher_ssm")
          solr_doc["lib_publisher_ssm"].should == ['Amazing Publisher']
        end
      end
      describe "place" do
        it "should be stored as a string" do
          item_xml = fixture( File.join("CUL_MODS", "mods-origin-info.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("origin_info_place_ssm")
          solr_doc.should include("origin_info_place_for_display_ssm")
          solr_doc["origin_info_place_ssm"].should == ['Such A Great Place', 'Such A Great valueUri Place']
          solr_doc["origin_info_place_for_display_ssm"].should == ['Such A Great Place']
        end
      end
      describe "edition" do
        it "should be stored as a string" do
          item_xml = fixture( File.join("CUL_MODS", "mods-origin-info.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("origin_info_edition_ssm")
          solr_doc["origin_info_edition_ssm"].should == ['First Edition']
        end
      end
    end
    describe "location" do
      describe "physicalLocation" do
        it "should be in text field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("all_text_teim")
          # check the mapped facet value
          solr_doc["all_text_teim"].join(' ').should include("Rare Book & Manuscript Library")
          # check the unmapped display value
          solr_doc["all_text_teim"].join(' ').should include("Rare Book & Manuscript Library")
        end
        it "should fall back to 'Non-Columbia Location' when untranslated" do
          item_xml = fixture( File.join("CUL_MODS", "mods-bad-repo.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("lib_repo_short_ssim")
          solr_doc.should include("lib_repo_long_sim")
          solr_doc.should include("lib_repo_full_ssim")
          solr_doc.should include("all_text_teim")
          solr_doc["lib_repo_short_ssim"].should include('Non-Columbia Location')
          solr_doc["lib_repo_long_sim"].should include('Non-Columbia Location')
          solr_doc["lib_repo_full_ssim"].should include('Non-Columbia Location')
          solr_doc["all_text_teim"].join(' ').should include('Non-Columbia Location')
          solr_doc["lib_repo_text_ssm"].should == 'Potentially Unpredictable Repo Text Name'
        end
      end
      describe "sublocation" do
        it "should be in text field and stored as a string" do
          item_xml = fixture( File.join("CUL_MODS", "mods-physical-location.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc.should include("location_sublocation_ssm")
          solr_doc["location_sublocation_ssm"].should include("exampleSublocation")
          solr_doc["all_text_teim"].join(' ').should include("exampleSublocation")
        end
      end
      describe "shelfLocator" do
        it "should be in text field and stored as a string" do
          item_xml = fixture( File.join("CUL_MODS", "mods-physical-location.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc.should include("location_shelf_locator_ssm")
          solr_doc["location_shelf_locator_ssm"].should include("(Box no.\n\t057)") # ssm field captures whitespace characters like tabs and newlines
          solr_doc["all_text_teim"].join(' ').should include("(Box no. 057)")
        end
      end
      describe "url" do
        it "item in context url should be stored as a string in its own field" do
          item_xml = fixture( File.join("CUL_MODS", "mods-top-level-location-vs-relateditem-location.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("lib_item_in_context_url_ssm")
          solr_doc["lib_item_in_context_url_ssm"].should == ["http://item-in-context.cul.columbia.edu/something/123"]
        end
        it "non-item in context urls should be stored together in a multivalued string field, separate from item in context url" do
          item_xml = fixture( File.join("CUL_MODS", "mods-top-level-location-vs-relateditem-location.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("lib_non_item_in_context_url_ssm")
          solr_doc["lib_non_item_in_context_url_ssm"].should == ["http://another-location.cul.columbia.edu/zzz/yyy", "http://great-url.cul.columbia.edu/ooo"]
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
      it "should index and store primary names" do
        names_xml = fixture( File.join("CUL_MODS", "mods-names.xml"))
        mods = descMetadata(@mock_inner, names_xml)
        solr_doc = mods.to_solr
        solr_doc["primary_name_sim"].should == ["Seminar 401"]
        solr_doc["primary_name_ssm"].should == ["Seminar 401"]
      end
    end
    describe "relatedItem (project)" do
      describe "[@type='Host, @displayLabel='Project']" do
        it "should be in facet field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("lib_project_short_ssim")
          solr_doc.should include("lib_project_full_ssim")
          solr_doc["lib_project_short_ssim"].should include("Successful Project Mapping For Short Project Title")
          solr_doc["lib_project_full_ssim"].should include("Successful Project Mapping For Full Project Title")
        end
        it "should be in text field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("Successful Project Mapping For Short Project Title")
          solr_doc["all_text_teim"].join(' ').should include("Successful Project Mapping For Full Project Title")
        end
        it "should fall back to full project name when untranslated" do
          item_xml = fixture( File.join("CUL_MODS", "mods-unmapped-project.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc.should include("lib_project_short_ssim")
          solr_doc.should include("lib_project_full_ssim")
          solr_doc["lib_project_short_ssim"].should include("Some Nonsense Project Name")
          solr_doc["lib_project_full_ssim"].should include("Some Nonsense Project Name")
          solr_doc["all_text_teim"].join(' ').should include("Some Nonsense Project Name")
        end
        describe "url" do
          it "should be stored as a string" do
            item_xml = fixture( File.join("CUL_MODS", "mods-top-level-location-vs-relateditem-location.xml") )
            mods_item = descMetadata(@mock_inner, item_xml)
            solr_doc = mods_item.to_solr
            solr_doc.should include("lib_project_url_ssm")
            solr_doc["lib_project_url_ssm"].should == ["http://not-the-item-url.cul.columbia.edu"]
          end
        end
      end
    end
    describe "relatedItem (Collection)" do
      describe "[@type='Host, @displayLabel='Collection']" do
        it "should be in facet field" do
          solr_doc = @mods_all.to_solr
          solr_doc.should include("lib_collection_sim")
          solr_doc["lib_collection_sim"].should include("Collection Facet Normalization Test")
        end
        it "should be in text field" do
          solr_doc = @mods_all.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["all_text_teim"].join(' ').should include("Collection Facet Normalization Test")
        end
      end
    end
    describe "relatedItem (Part)" do
      describe "[@type='constituent]" do
        it "should be in text field and in a stored field" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("all_text_teim")
          solr_doc["lib_part_ssm"].should include("Constituent item / part")
          solr_doc["all_text_teim"].join(' ').should include("Constituent item / part")
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
        it "should have separate indexes of local and aat" do
          mods_xml = fixture( File.join("CUL_MODS", "mods-physical-description.xml") )
          mods_ds = descMetadata(@mock_inner, mods_xml)
          solr_doc = mods_ds.to_solr
          solr_doc["physical_description_form_aat_sim"].should eql(["Books"])
          solr_doc["physical_description_form_local_sim"].should eql(["minutes"])
        end
      end
    end
    describe "language" do
      describe "languageTerm" do
        it "code should be faceted and texted" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("language_language_term_code_ssim")
          solr_doc["language_language_term_code_ssim"].should include("eng")
          solr_doc["all_text_teim"].join(' ').should include(" eng")
        end
        it "text should be faceted and texted" do
          solr_doc = @mods_item.to_solr
          solr_doc.should include("language_language_term_text_ssim")
          solr_doc["language_language_term_text_ssim"].should include("English")
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
      it "collects date notes and non-date notes, and prepends appropriate text before certain note types" do
        item_xml = fixture( File.join("CUL_MODS", "mods-notes.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr

        solr_doc["all_text_teim"].should include("Basic note")
        solr_doc["all_text_teim"].should include("Banana note")
        solr_doc["all_text_teim"].should include("Date note")
        solr_doc["all_text_teim"].should include("Date source note")


        solr_doc["lib_non_date_notes_ssm"].should == ["Basic note", "Banana note", "View Direction: WEST"]
        solr_doc["lib_date_notes_ssm"].should == ["Date note", "Date source note"]
      end
    end
    describe "abstract" do
      it "should be texted and stored" do
        item_xml = fixture( File.join("CUL_MODS", "mods-001.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
        solr_doc["all_text_teim"].join(' ').should include("This is the abstract")
        solr_doc["abstract_ssm"].should include("This is the abstract")
      end
    end
    describe "tableOfContents" do
      it "should be texted and stored" do
        item_xml = fixture( File.join("CUL_MODS", "mods-001.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
        solr_doc["all_text_teim"].join(' ').should include("This is the table of contents")
        solr_doc["table_of_contents_ssm"].should include("This is the table\nof\ncontents")
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
      end
      describe "alternative titles" do
        it "should have all forms of alternative titles" do
          item_xml = fixture( File.join("CUL_MODS", "mods-titles.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc["alternative_title_ssm"].should == ["The Alternative Title", "The Abbrev. Title", "The Firefighter Title", "Los Fotos"]
        end
        it "should not contain the main title" do
          item_xml = fixture( File.join("CUL_MODS", "mods-titles.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc["alternative_title_ssm"].join(' ').should_not include("Photographs")
        end
      end
      describe "all /mods/titleInfo/title elements" do
        it "should have the main title and alternative title (among others) in the title field" do
          item_xml = fixture( File.join("CUL_MODS", "mods-titles.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          solr_doc["title_ssm"].should include("The Photographs")
          solr_doc["title_ssm"].should include("The Alternative Title")
        end
        it "should text all the titles" do
          item_xml = fixture( File.join("CUL_MODS", "mods-titles.xml") )
          mods_item = descMetadata(@mock_inner, item_xml)
          solr_doc = mods_item.to_solr
          fulltext_text = solr_doc["all_text_teim"].join(' ')
          fulltext_text.should include("Fotos")
          fulltext_text.should include("The Alternative Title")
          fulltext_text.should include("The Abbrev. Title")
          fulltext_text.should include("The Firefighter Title")
          fulltext_text.should include("Los Fotos")
        end
      end
    end
    describe "subjects" do
      it "should have the expected subjects in both stored string and text fields" do
        item_xml = fixture( File.join("CUL_MODS", "mods-subjects.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
        subjects = ["What A Topic", "Great Geographic Subject", "Jay, John, 1745-1829", "Smith, John, 1440-1540", "So Temporal", "The Best Subject Title I've Ever Seen!", "A Very Accurate Genre"]
        solr_doc["lib_all_subjects_ssm"].should == subjects
        solr_doc["lib_all_subjects_teim"].should == subjects
        solr_doc["all_text_teim"].join(' ').should include("What A Topic")
        solr_doc["all_text_teim"].join(' ').should include("A Very Accurate Genre")
      end
      it "should not be pulling in subjects that we're not interested in, like subject occupation" do
        item_xml = fixture( File.join("CUL_MODS", "mods-subjects.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
        ignored_subject = 'We Are Currently Ignoring Subject Occupation'
        solr_doc["lib_all_subjects_ssm"].should_not include(ignored_subject)
        solr_doc["lib_all_subjects_teim"].should_not include(ignored_subject)
      end
      it 'should not be pulling in topic subjects with authority="Durst" into lib_all_subjects' do
        item_xml = fixture( File.join("CUL_MODS", "mods-subjects.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
        ignored_subject = 'Durst subject that should be ignored'
        solr_doc["lib_all_subjects_ssm"].should_not include(ignored_subject)
        solr_doc["lib_all_subjects_teim"].should_not include(ignored_subject)
      end
      it 'should be pulling in topic subjects with authority="Durst" into durst_subjects_ssim' do
        item_xml = fixture( File.join("CUL_MODS", "mods-subjects.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
        durst_subject = 'Durst subject that should be ignored'
        solr_doc["durst_subjects_ssim"].should include(durst_subject)
      end
      it "should extract hierarchical subjects" do
        item_xml = fixture( File.join("CUL_MODS", "mods-subjects.xml") )
        mods_item = descMetadata(@mock_inner, item_xml)
        solr_doc = mods_item.to_solr
        hierarchical_subjects = []
        expected_places = {
          'subject_hierarchical_geographic_country_ssim' => ['United States'],
          'subject_hierarchical_geographic_province_ssim' => ['Nova Scotia'],
          'subject_hierarchical_geographic_region_ssim' => ['Northeast'],
          'subject_hierarchical_geographic_state_ssim' => ['New York'],
          'subject_hierarchical_geographic_county_ssim' => ['Westchester'],
          'subject_hierarchical_geographic_borough_ssim' => ['Brooklyn'],
          'subject_hierarchical_geographic_city_ssim' => ['White Plains'],
          'subject_hierarchical_geographic_neighborhood_ssim' => ['The Backpacking District'],
          'subject_hierarchical_geographic_zip_code_ssim' => ['10027'],
          'subject_hierarchical_geographic_street_ssim' => ['123 Broadway'],
        }
        expected_places.each {|solr_key, value|
          solr_doc[solr_key].should == value
          value.each {|val|
            solr_doc["all_text_teim"].should include(val)
          }
        }
      end
    end
  end
end
