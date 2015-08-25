require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Hydra::Datastreams::ModsDocument", type: :unit do
  describe "#to_solr" do
    let(:mock_inner) do
      mock = double('inner object')
      mock.stub(:"new_record?" => false, :repository => mock_repo, :pid => nil)
      mock
    end
    let(:mock_repo) do
      mock = double('repository')
      mock.stub(config: {}, datastream_profile: {}, datastream_dissemination: 'My Content')
      mock
    end
    let(:mods_ds) { descMetadata(mock_inner, mods_src) }
    let(:solr_doc) { mods_ds.to_solr }
    let(:all_text) { solr_doc['all_text_teim']}
    let(:all_text_joined) { all_text.join(' ')}
    subject {
      solr_doc
    }
    context "with non-MODS content" do
      let(:mods_src) { fixture( File.join("CUL_DC", "dc.xml") ) }
      it do
        is_expected.to be
        is_expected.to be_empty
      end
    end
    context "has date cataloging" do
      context "with dates encoded as 'u' characters" do
        context "that are less that 4 characters long" do
          let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-range-short-years.xml") ) }
          it "handles positive (CE) or negative (BCE)" do
            expect(subject["origin_info_date_other_ssm"]).to eql ['-99']
            expect(subject["origin_info_date_other_start_ssm"]).to eql ['-99']
            expect(subject["origin_info_date_other_end_ssm"]).to eql ['25']
            expect(subject["lib_start_date_year_itsi"]).to eql -99
            expect(subject["lib_end_date_year_itsi"]).to eql 25
            expect(subject["lib_date_year_range_si"]).to eql '-0099-0025'
            expect(subject["lib_date_textual_ssm"]).to eql ['Between 99 BCE and 25 CE'] # Derived from key date
          end
        end
        context "that represent a range with partial 'u' characters" do
          let(:mods_src) { fixture( File.join("CUL_MODS", "mods-dates-with-some-u-characters.xml") ) }
          it "replaces 'u' characters with zeroes when they're part of, but not all of, a year's digits" do
            expect(subject["lib_date_year_range_si"]).to eql '1870-1900'
          end
        end
        context "that encode the end date with all 'u' characters" do
          let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-end-with-all-u-characters.xml") ) }
          it "uses only the start date" do
            expect(subject["lib_date_year_range_si"]).to eql '1870-1870'
          end
        end
        context "that encode the start date with all 'u' characters" do
          let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-start-with-all-u-characters.xml") ) }
          it "uses only the end date" do
            expect(subject["lib_date_year_range_si"]).to eql '1920-1920'
          end
        end
        context "that encode both start and end date with all 'u' characters" do
          let(:mods_src) { fixture( File.join("CUL_MODS", "mods-dates-with-all-u-characters.xml") ) }
          it "should not populate the lib_date_year_range_si field" do
            expect(subject["lib_date_year_range_si"]).not_to be
          end
        end
      end
      context "with textual (non-key) dates" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-textual-date.xml") ) }
        it do
          expect(subject["lib_date_textual_ssm"]).to eql ['Some time around 1919']
        end
      end
      context "with date issued (single)" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-issued-single.xml") ) }
        it do
          expect(subject["origin_info_date_issued_ssm"]).to eql ['1700']
          expect(subject["origin_info_date_issued_start_ssm"]).to eql nil
          expect(subject["origin_info_date_issued_end_ssm"]).to eql nil
          expect(all_text_joined).to include("1700")
          expect(subject["lib_start_date_year_itsi"]).to eql 1700
          expect(subject["lib_end_date_year_itsi"]).to eql 1700
          expect(subject["lib_date_year_range_si"]).to eql '1700-1700'
          expect(subject["lib_date_textual_ssm"]).to eql ['1700'] # Derived from key date
        end
      end 
      context "with date issued (range)" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-issued-range.xml") ) }
        it do
          expect(subject["origin_info_date_issued_ssm"]).to eql ['1701']
          expect(subject["origin_info_date_issued_start_ssm"]).to eql ['1701']
          expect(subject["origin_info_date_issued_end_ssm"]).to eql ['1702']
          expect(subject["lib_start_date_year_itsi"]).to eql 1701
          expect(subject["lib_end_date_year_itsi"]).to eql 1702
          expect(subject["lib_date_year_range_si"]).to eql '1701-1702'
          expect(subject["lib_date_textual_ssm"]).to eql ['Between 1701 and 1702'] # Derived from key date
        end
      end 
      context "with date created (single)" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-created-single.xml") ) }
        it do
          expect(subject["origin_info_date_created_ssm"]).to eql ['1800']
          expect(subject["origin_info_date_created_start_ssm"]).to eql nil
          expect(subject["origin_info_date_created_end_ssm"]).to eql nil
          expect(subject["lib_start_date_year_itsi"]).to eql 1800
          expect(subject["lib_end_date_year_itsi"]).to eql 1800
          expect(subject["lib_date_year_range_si"]).to eql '1800-1800'
          expect(subject["lib_date_textual_ssm"]).to eql ['1800'] # Derived from key date
        end
      end 
      context "with date created (range) as iso8601" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-created-range.xml") ) }
        it do
          expect(subject["lib_start_date_year_itsi"]).to eql 1801
          expect(subject["lib_end_date_year_itsi"]).to eql 1802
          expect(subject["lib_date_year_range_si"]).to eql '1801-1802'
          expect(subject["lib_date_textual_ssm"]).to eql ['Between 1801 and 1802'] # Derived from key date
        end
      end 
      context "with date other (single)" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-other-single.xml") ) }
        it do
          expect(subject["origin_info_date_other_ssm"]).to eql ['1900']
          expect(subject["origin_info_date_other_start_ssm"]).to eql nil
          expect(subject["origin_info_date_other_end_ssm"]).to eql nil
          expect(subject["lib_start_date_year_itsi"]).to eql 1900
          expect(subject["lib_end_date_year_itsi"]).to eql 1900
          expect(subject["lib_date_year_range_si"]).to eql '1900-1900'
          expect(subject["lib_date_textual_ssm"]).to eql ['1900'] # Derived from key date
        end
      end 
      context "with date other (range)" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-date-other-range.xml") ) }
        it do
          expect(subject["origin_info_date_other_ssm"]).to eql ['1901']
          expect(subject["origin_info_date_other_start_ssm"]).to eql ['1901']
          expect(subject["origin_info_date_other_end_ssm"]).to eql ['1902']
          expect(subject["lib_start_date_year_itsi"]).to eql 1901
          expect(subject["lib_end_date_year_itsi"]).to eql 1902
          expect(subject["lib_date_year_range_si"]).to eql '1901-1902'
          expect(subject["lib_date_textual_ssm"]).to eql ['Between 1901 and 1902'] # Derived from key date
        end
      end
    end
    context "that has originInfo cataloging" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-origin-info.xml") ) }
      it "should store publisher as a string" do
        is_expected.to include("origin_info_publisher_ssm")
        expect(subject["lib_publisher_ssm"]).to eql ['Amazing Publisher']
      end
      it "should store place as a string" do
        is_expected.to include("origin_info_place_ssm")
        is_expected.to include("origin_info_place_for_display_ssm")
        expect(subject["origin_info_place_ssm"]).to eql ['Such A Great Place', 'Such A Great valueUri Place']
        expect(subject["origin_info_place_for_display_ssm"]).to eql ['Such A Great Place']
      end
      it "should store edition as a string" do
        is_expected.to include("origin_info_edition_ssm")
        expect(subject["origin_info_edition_ssm"]).to eql ['First Edition']
      end
    end
    context "has physical location cataloged" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-physical-location.xml") ) }
      context "with a sublocation" do
        subject { solr_doc['location_sublocation_ssm'] }
        it do
          is_expected.to be
          is_expected.to include("exampleSublocation")
          expect(all_text_joined).to include("exampleSublocation")
        end
      end
      context "with a shelfLocator" do
        subject { solr_doc['location_shelf_locator_ssm'] }
        it do
          is_expected.to be
          is_expected.to include("(Box no.\n\t057)")
          expect(all_text_joined).to include("(Box no. 057)")
        end
      end
      context "with a non-Columbia repository" do
        let(:mods_src) { fixture( File.join("CUL_MODS", "mods-bad-repo.xml") ) }
        it "should fall back to 'Non-Columbia Location' when untranslated" do
          is_expected.to include("lib_repo_short_ssim")
          is_expected.to include("lib_repo_long_sim")
          is_expected.to include("lib_repo_full_ssim")
          expect(subject["lib_repo_short_ssim"]).to include('Non-Columbia Location')
          expect(subject["lib_repo_long_sim"]).to include('Non-Columbia Location')
          expect(subject["lib_repo_full_ssim"]).to include('Non-Columbia Location')
          expect(subject["lib_repo_text_ssm"]).to eql 'Potentially Unpredictable Repo Text Name'
          expect(all_text_joined).to include('Non-Columbia Location')
        end
      end
    end
    context "has unmapped project names cataloged" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-unmapped-project.xml") ) }
      it do
        is_expected.to include("lib_project_short_ssim")
        is_expected.to include("lib_project_full_ssim")
        expect(solr_doc["lib_project_short_ssim"]).to include("Some Nonsense Project Name")
        expect(solr_doc["lib_project_full_ssim"]).to include("Some Nonsense Project Name")
        expect(all_text_joined).to include("Some Nonsense Project Name")
      end
    end
    context "has URLs cataloged" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-top-level-location-vs-relateditem-location.xml") ) }
      context "for the project" do
        subject { solr_doc['lib_project_url_ssm'] }
        it do
          is_expected.to be
          is_expected.to eql(["http://not-the-item-url.cul.columbia.edu"])
        end
      end
      context "for an item in context" do
        subject { solr_doc['lib_item_in_context_url_ssm'] }
        it do
          is_expected.to be
          is_expected.to eql ["http://item-in-context.cul.columbia.edu/something/123"]
        end
      end
      context "for a non-item in context" do
        subject { solr_doc['lib_non_item_in_context_url_ssm'] }
        it do
          is_expected.to be
          is_expected.to eql ["http://another-location.cul.columbia.edu/zzz/yyy", "http://great-url.cul.columbia.edu/ooo"]
        end
      end
    end
    context "has names cataloged" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-names.xml") ) }
      context "as primary names" do
        context "the facetable value" do
          subject { solr_doc['primary_name_sim'] }
          it do
            is_expected.to be
            is_expected.to eql ["Seminar 401"]
          end
        end
        context "the stored value" do
          subject { solr_doc['primary_name_ssm'] }
          it do
            is_expected.to be
            is_expected.to eql ["Seminar 401"]
          end
        end
      end
    end
    context "has all the common subsite cataloging" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-all.xml") ) }
      context "has a recipient name cataloged" do
        it do
          expect(all_text_joined).to include("Name, Recipient")
        end
      end
      context "with a collection relatedItem cataloged" do
        subject { solr_doc["lib_collection_sim"] }
        it "should normalize collection names" do
          is_expected.to be
          is_expected.to include("Collection Facet Normalization Test")
          expect(all_text_joined).to include("Collection Facet Normalization Test")
        end
      end
    end
    context "has description of an item in the MODS source" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-item.xml") ) }
      context "copied" do
        it "should include nonSort text in display title and exclude it from index title" do
          expect(subject["title_display_ssm"]).to include('The Manuscript, unidentified')
          expect(subject["title_si"]).to eql "Manuscript, unidentified"
        end
        it "should create the expected Solr hash for mapped project values" do
          # check the mapped facet value
          expect(subject["lib_project_short_ssim"]).to include("Successful Project Mapping For Short Project Title")
          expect(subject["lib_project_full_ssim"]).to include("Successful Project Mapping For Full Project Title")
          # check that various repo mappings are working
          expect(subject["lib_repo_short_ssim"]).to include("Rare Book & Manuscript Library")
          expect(subject["lib_repo_long_sim"]).to include("Rare Book & Manuscript Library")
          expect(subject["lib_repo_full_ssim"]).to include("Rare Book & Manuscript Library, Columbia University")
          # check the language term code and text fields
          expect(subject["language_language_term_code_ssim"]).to eql ['eng']
          expect(subject["language_language_term_text_ssim"]).to eql ['English']
          # check the date fields
          expect(subject["origin_info_date_created_start_ssm"]).to eql ['1801']
          expect(subject["origin_info_date_created_end_ssm"]).to eql ['1802']
          # check specially generated start_date and end_date fields
          expect(subject["lib_start_date_year_itsi"]).to eql 1801
          expect(subject["lib_end_date_year_itsi"]).to eql 1802
          expect(subject["lib_date_year_range_si"]).to eql '1801-1802'
          expect(subject["lib_date_textual_ssm"]).to eql ['Between 1801 and 1802'] # Derived from key date
          expect(subject["subject_topic_sim"]).to eql ['Indians of North America--Missions']
          expect(subject["subject_geographic_sim"]).to eql ['Rosebud Indian Reservation (S.D.)']
          expect(all_text_joined).to include("Indians of North America")
          expect(all_text_joined).to include("Rosebud Indian Reservation")
        end
      end
      context "with a repository cataloged" do
        it "should be in text field" do
          # check the mapped facet value
          expect(all_text_joined).to include("Rare Book & Manuscript Library")
        end
      end
      context "with a project relatedItem cataloged" do
        context "the short project name value" do
          subject { solr_doc["lib_project_short_ssim"] }
          it do
            is_expected.to be
            is_expected.to include("Successful Project Mapping For Short Project Title")
            expect(all_text_joined).to include("Successful Project Mapping For Short Project Title")
          end
        end
        context "the full project name value" do
          subject { solr_doc["lib_project_full_ssim"] }
          it do
            is_expected.to be
            is_expected.to include("Successful Project Mapping For Full Project Title")
            expect(all_text_joined).to include("Successful Project Mapping For Full Project Title")
          end
        end
      end
      context "with a constituent relatedItem cataloged" do
        subject { solr_doc["lib_part_ssm"] }
        it do
          is_expected.to include("Constituent item / part")
          expect(all_text_joined).to include("Constituent item / part")
        end
      end
      context "with a form facet from physicalDescription" do
        subject { solr_doc["lib_format_sim"] }
        it do
          is_expected.to be
          is_expected.to include("books")
          expect(all_text_joined).to include("books")
        end
      end
      context "with language cataloged as a code" do
        subject { solr_doc["language_language_term_code_ssim"] }
        it do
          is_expected.to be
          is_expected.to include("eng")
          expect(all_text_joined).to include(" eng")
        end
      end
      context "with language cataloged as a code" do
        subject { solr_doc["language_language_term_text_ssim"] }
        it do
          is_expected.to be
          is_expected.to include("English")
          expect(all_text_joined).to include("English")
        end
      end
    end
    context "has authority values for form under physicalDescription" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-physical-description.xml") ) }
      context "from a local authority" do
        subject { solr_doc['physical_description_form_local_sim'] }
        it do
          is_expected.to be
          is_expected.to eql(["minutes"])
        end
      end
      context "from the aat authority" do
        subject { solr_doc['physical_description_form_aat_sim'] }
        it do
          is_expected.to be
          is_expected.to eql(["Books"])
        end
      end
    end
    context "has descriptive text fields in the MODS source" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-001.xml") ) }
      context "the notes" do
        it "should be texted" do
          expect(all_text_joined).to include("Original PRD customer order number")
        end
        context "with date notes and non-date notes" do
          let(:mods_src) { fixture( File.join("CUL_MODS", "mods-notes.xml") ) }
          it "should prepend appropriate text before certain note types" do
            expect(all_text).to include("Basic note")
            expect(all_text).to include("Banana note")
            expect(all_text).to include("Date note")
            expect(all_text).to include("Date source note")


            expect(subject["lib_non_date_notes_ssm"]).to eql ["Basic note", "Banana note", "View Direction: WEST"]
            expect(subject["lib_date_notes_ssm"]).to eql ["Date note", "Date source note"]
          end
        end
      end
      context "the abstract" do
        it "should be texted and stored" do
          expect(subject["abstract_ssm"]).to include("This is the abstract")
          all_text_joined.should include("This is the abstract")
        end
      end
      context "the tableOfContents" do
        it "should be texted and stored" do
          expect(subject["table_of_contents_ssm"]).to include("This is the table\nof\ncontents")
          all_text_joined.should include("This is the table of contents")
        end
      end
    end
    context "has document title elements in the MODS source" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-titles.xml") ) }
      it "should have the expected main sort title" do
        expect(subject["title_si"]).to include("Photographs")
      end
      context "include alternative titles" do
        it "should have all forms of alternative titles in the relevant field" do
          expect(subject["alternative_title_ssm"]).to eql(["The Alternative Title", "The Abbrev. Title", "The Firefighter Title", "Los Fotos"])
        end
        it "should not contain the main title in the alternative field" do
          expect(subject["alternative_title_ssm"].join(' ')).not_to include("Photographs")
        end
      end
      it "should have the main title and alternative title (among others) in the stored title field" do
        expect(subject["title_ssm"]).to include("The Photographs")
        expect(subject["title_ssm"]).to include("The Alternative Title")
      end
      context "in the full text field" do
        subject { all_text_joined }
        it do
          is_expected.to include("Fotos")
          is_expected.to include("The Alternative Title")
          is_expected.to include("The Abbrev. Title")
          is_expected.to include("The Firefighter Title")
          is_expected.to include("Los Fotos")
        end
      end
    end
    context "has subjects in the MODS source" do
      let(:mods_src) { fixture( File.join("CUL_MODS", "mods-subjects.xml") ) }
      it "should have the expected subjects in both stored string and text fields" do
        subjects = ["What A Topic", "Great Geographic Subject", "Jay, John, 1745-1829", "Smith, John, 1440-1540", "So Temporal", "The Best Subject Title I've Ever Seen!", "A Very Accurate Genre"]
        expect(subject["lib_all_subjects_ssm"]).to eql subjects
        expect(subject["lib_all_subjects_teim"]).to eql subjects
        expect(all_text_joined).to include("What A Topic")
        expect(all_text_joined).to include("A Very Accurate Genre")
      end
      it "should not be pulling in subjects that we're not interested in, like subject occupation" do
        ignored_subject = 'We Are Currently Ignoring Subject Occupation'
        expect(subject["lib_all_subjects_ssm"]).not_to include(ignored_subject)
        expect(subject["lib_all_subjects_teim"]).not_to include(ignored_subject)
      end
      it 'should not be pulling in topic subjects with authority="Durst" into lib_all_subjects' do
        ignored_subject = 'Durst subject that should be ignored'
        expect(subject["lib_all_subjects_ssm"]).not_to include(ignored_subject)
        expect(subject["lib_all_subjects_teim"]).not_to include(ignored_subject)
      end
      it 'should be pulling in topic subjects with authority="Durst" into durst_subjects_ssim' do
        durst_subject = 'Durst subject that should be ignored'
        expect(subject["durst_subjects_ssim"]).to include(durst_subject)
      end
      it "should extract hierarchical subjects" do
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
          expect(subject[solr_key]).to eql value
          value.each {|val|
            expect(all_text).to include(val)
          }
        }
      end
    end
  end
end