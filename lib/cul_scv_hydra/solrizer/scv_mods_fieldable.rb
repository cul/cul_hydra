module Cul::Scv::Hydra::Solrizer
	module ScvModsFieldable
    extend ActiveSupport::Concern
    include Solrizer::DefaultDescriptors::Normal

    MODS_NS = {'mods'=>'http://www.loc.gov/mods/v3'}

    module ClassMethods
      def value_mapper(maps=nil)
        @value_mapper ||= ValueMapper.new(maps)
      end

      def map_field(field_key, map_key)
        value_mapper.map_field(field_key, map_key)
      end

      def map_value(field_key, value_key)
        value_mapper.map_value(field_key, value_key)
      end

      def maps_field?(field_key)
        value_mapper.maps_field? field_key
      end
    end

    def mods
      ng_xml.xpath('/mods:mods', MODS_NS).first
    end

    def projects
      mods.xpath("./mods:relatedItem[@type='host' and @displayLabel='Project']", MODS_NS).collect do |p_node|
        ScvModsFieldable.normalize(main_title(p_node), true)
      end
    end

    def collections
      mods.xpath("./mods:relatedItem[@type='host' and @displayLabel='Collection']", MODS_NS).collect do |p_node|
        ScvModsFieldable.normalize(main_title(p_node), true)
      end
    end

    def sort_title(node=mods)
      # include only the untyped [!@type] titleInfo, exclude noSort
      base_text = ''
      t = node.xpath('./mods:titleInfo[not(@type)]', MODS_NS).first
      if t
        t.children.each do |child|
          base_text << child.text unless child.name == 'nonSort'
        end
      end
      base_text = ScvModsFieldable.normalize(base_text, true)
      base_text = nil if base_text.empty?
      base_text
    end

    def main_title(node=mods)
      # include only the untyped [!@type] titleInfo
      t = node.xpath('./mods:titleInfo[not(@type)]', MODS_NS).first
      if t
        ScvModsFieldable.normalize(t.text)
      else
        nil
      end
    end

    def titles(node=mods)
      # all titles without descending into relatedItems
      # For now, this only includes the main title and selected alternate_titles
      all_titles = []
      all_titles << main_title unless main_title.nil?
      all_titles += alternative_titles unless alternative_titles.nil?
    end

    def alternative_titles(node=mods)
      node.xpath('./mods:titleInfo[@type and (@type="alternative" or @type="abbreviated" or @type="translated" or @type="uniform")]', MODS_NS).collect do |t|
        ScvModsFieldable.normalize(t.text)
      end
		end

    def names(role_authority=nil, role=nil)
      # get all the name nodes
      # keep all child text except the role terms
      xpath = "./mods:name"
      unless role_authority.nil?
        xpath << "/mods:role/mods:roleTerm[@authority='#{role_authority.to_s}'"
        unless role.nil?
          xpath << " and normalize-space(text()) = '#{role.to_s.strip}'"
        end
        xpath << "]/ancestor::mods:name"
      end
      names = mods.xpath(xpath, MODS_NS).collect do |node|
        base_text = node.xpath('./mods:namePart', MODS_NS).collect { |c| c.text }.join(' ')
        ScvModsFieldable.normalize(base_text, true)
      end

      # Note: Removing subject names from name field extraction.
      # See: https://issues.cul.columbia.edu/browse/DCV-231 and https://issues.cul.columbia.edu/browse/SCV-102
      #xpath = "./mods:subject" + xpath[1,xpath.length]
      #mods.xpath(xpath, MODS_NS).each do |node|
      #  base_text = node.xpath('./mods:namePart', MODS_NS).collect { |c| c.text }.join(' ')
      #  names << ScvModsFieldable.normalize(base_text, true)
      #end

      names
    end

    def dates(node=mods)
      # get all the dateIssued with keyDate = 'yes', but not point = 'end'
    end

    def formats(node=mods)
      # get all the form values with authority != 'marcform'
      node.xpath("./mods:physicalDescription/mods:form[@authority != 'marcform']", MODS_NS).collect do |n|
        ScvModsFieldable.normalize(n.text)
      end
    end

    def repository_code(node=mods)
      # get the location/physicalLocation[@authority = 'marcorg']
      repo_code_node = node.xpath("./mods:location/mods:physicalLocation[@authority = 'marcorg']", MODS_NS).first

      if repo_code_node
				ScvModsFieldable.normalize(repo_code_node.text)
			else
				return nil
			end
    end

    def repository_text(node=mods)
      # get the location/physicalLocation[not(@authority)]
      repo_text_node = node.xpath("./mods:location/mods:physicalLocation[not(@authority)]", MODS_NS).first

      if repo_text_node
				ScvModsFieldable.normalize(repo_text_node.text)
			else
				return nil
			end
    end

    def translate_repo_marc_code(code, type)
			#code = ScvModsFieldable.normalize(code)

			if type == 'short'
				return translate_with_default(SHORT_REPO, code, 'Non-Columbia Location')
			elsif type == 'long'
				return translate_with_default(LONG_REPO, code, 'Non-Columbia Location')
			elsif type == 'full'
				return translate_with_default(FULL_REPO, code, 'Non-Columbia Location')
			end

			return nil
		end

    def translate_project_title(project_title, type)
			normalized_project_title = ScvModsFieldable.normalize(project_title)

			if type == 'short'
				return translate_with_default(SHORT_PROJ, normalized_project_title, normalized_project_title)
			elsif type == 'full'
				return translate_with_default(FULL_PROJ, normalized_project_title, normalized_project_title)
			end

			return nil
		end

    def shelf_locators(node=mods)
      node.xpath("./mods:location/mods:shelfLocator", MODS_NS).collect do |n|
        ScvModsFieldable.normalize(n.text, true)
      end
    end

    def textual_dates(node=mods)
			dates = []
			node.xpath("./mods:originInfo/mods:dateCreated[not(@keyDate) and not(@point) and not(@w3cdtf)]", MODS_NS).collect do |n|
        dates << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:originInfo/mods:dateIssued[not(@keyDate) and not(@point) and not(@w3cdtf)]", MODS_NS).collect do |n|
        dates << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:originInfo/mods:dateOther[not(@keyDate) and not(@point) and not(@w3cdtf)]", MODS_NS).collect do |n|
        dates << ScvModsFieldable.normalize(n.text, true)
      end
			return dates
		end

    def date_range_to_textual_date(start_year, end_year)
			start_year = start_year.to_i.to_s # Remove zero-padding if present
			end_year = end_year.to_i.to_s # Remove zero-padding if present

			if start_year == end_year
				return [start_year]
			else
				return [('Between ' +
					(start_year.to_i > 0 ? start_year : start_year[1,start_year.length] + ' BCE') +
					' and ' +
					(end_year.to_i > 0 ? (start_year.to_i > 0 ? end_year : end_year + ' CE') : end_year[1,end_year.length] + ' BCE')
				)]
			end
		end

    def date_notes(node=mods)
			date_notes = []
			node.xpath("./mods:note[@type = 'date' or @type = 'date source']", MODS_NS).collect do |n|
        date_notes << ScvModsFieldable.normalize(n.text, true)
      end
			return date_notes
		end

    def non_date_notes(node=mods)
			non_date_notes = []
			node.xpath("./mods:note[not(@type) or (@type != 'date' and @type != 'date source')]", MODS_NS).collect do |n|
        non_date_notes << ScvModsFieldable.normalize(n.text, true)
      end
			return non_date_notes
		end

    def item_in_context_url(node=mods)
			item_in_context_url_val = []
			node.xpath("./mods:location/mods:url[@access='object in context' and @usage='primary display']", MODS_NS).collect do |n|
        item_in_context_url_val << ScvModsFieldable.normalize(n.text, true)
      end
			item_in_context_url_val
		end

    def project_url(node=mods)
			project_url_val = []
			node.xpath("./mods:relatedItem[@type='host' and @displayLabel='Project']/mods:location/mods:url", MODS_NS).collect do |n|
        project_url_val << ScvModsFieldable.normalize(n.text, true)
      end
			project_url_val
		end

    def all_subjects(node=mods)
			list_of_subjects = []

			node.xpath("./mods:subject/mods:topic", MODS_NS).collect do |n|
        list_of_subjects << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:subject/mods:geographic", MODS_NS).collect do |n|
        list_of_subjects << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:subject/mods:name", MODS_NS).collect do |n|
        list_of_subjects << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:subject/mods:temporal", MODS_NS).collect do |n|
        list_of_subjects << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:subject/mods:titleInfo", MODS_NS).collect do |n|
        list_of_subjects << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:subject/mods:genre", MODS_NS).collect do |n|
        list_of_subjects << ScvModsFieldable.normalize(n.text, true)
      end

			return list_of_subjects
		end

    def origin_info_place(node=mods)
			places = []
			node.xpath("./mods:originInfo/mods:place/mods:placeTerm", MODS_NS).collect do |n|
        places << ScvModsFieldable.normalize(n.text, true)
      end
			return places
		end

    def origin_info_place_for_display(node=mods)
			# If there are multiple origin_info place elements, choose only the ones without valueURI attributes.  Otherwise show the others.
			places_with_uri = []
			places_without_uri = []
			node.xpath("./mods:originInfo/mods:place/mods:placeTerm[@valueURI]", MODS_NS).collect do |n|
        places_with_uri << ScvModsFieldable.normalize(n.text, true)
      end
			node.xpath("./mods:originInfo/mods:place/mods:placeTerm[not(@valueURI)]", MODS_NS).collect do |n|
        places_without_uri << ScvModsFieldable.normalize(n.text, true)
      end

			puts 'places_with_uri: ' + places_with_uri.inspect
			puts 'places_without_uri: ' + places_without_uri.inspect

			return (places_without_uri.length > 0 ? places_without_uri : places_with_uri)
		end

    def to_solr(solr_doc={})
      solr_doc = (defined? super) ? super : solr_doc

      solr_doc["all_text_teim"] ||= []

      solr_doc["title_si"] = sort_title
      solr_doc["title_ssm"] = titles
      solr_doc["alternative_title_ssm"] = alternative_titles
      solr_doc["all_text_teim"] += solr_doc["alternative_title_ssm"]
      solr_doc["lib_collection_sim"] = collections
      solr_doc["lib_name_sim"] = names
      solr_doc["lib_name_teim"] = solr_doc["lib_name_sim"]
      solr_doc["all_text_teim"] += solr_doc["lib_name_teim"]
      solr_doc["lib_all_subjects_ssm"] = all_subjects
      solr_doc["lib_all_subjects_teim"] = solr_doc["lib_all_subjects_ssm"]
      solr_doc["all_text_teim"] += solr_doc["lib_all_subjects_teim"]
      solr_doc["lib_name_ssm"] = solr_doc["lib_name_sim"]
      solr_doc["lib_author_sim"] = names(:marcrelator, 'aut')
      solr_doc["lib_recipient_sim"] = names(:marcrelator, 'rcp')
      solr_doc["lib_format_sim"] = formats
      solr_doc["lib_shelf_sim"] = shelf_locators
      solr_doc["lib_date_textual_ssm"] = textual_dates
      solr_doc["lib_date_notes_ssm"] = date_notes
      solr_doc["lib_non_date_notes_ssm"] = non_date_notes
      solr_doc["lib_item_in_context_url_ssm"] = item_in_context_url
      solr_doc["lib_project_url_ssm"] = project_url
      solr_doc["origin_info_place_ssm"] = origin_info_place
      solr_doc["origin_info_place_for_display_ssm"] = origin_info_place_for_display

      repo_marc_code = repository_code
      unless repo_marc_code.nil?
				solr_doc["lib_repo_short_ssim"] = [translate_repo_marc_code(repo_marc_code, 'short')]
				solr_doc["lib_repo_long_sim"] = [translate_repo_marc_code(repo_marc_code, 'long')]
				solr_doc["lib_repo_full_ssim"] = [translate_repo_marc_code(repo_marc_code, 'full')]
			end
      solr_doc["lib_repo_text_ssm"] = repository_text

      project_titles = projects
      unless project_titles.nil?
				solr_doc["lib_project_short_ssim"] = []
				solr_doc["lib_project_full_ssim"] = []
				project_titles.each {|project_title|
					solr_doc["lib_project_short_ssim"] << translate_project_title(project_title, 'short')
					solr_doc["lib_project_full_ssim"] << translate_project_title(project_title, 'full')
				}
				solr_doc["lib_project_short_ssim"].uniq!
				solr_doc["lib_project_full_ssim"].uniq!
			end

      # Create convenient start and end date values based on one of the many possible originInfo/dateX elements.
      possible_start_date_fields = ['origin_info_date_issued_ssm', 'origin_info_date_issued_start_ssm', 'origin_info_date_created_ssm', 'origin_info_date_created_start_ssm', 'origin_info_date_other_ssm', 'origin_info_date_other_start_ssm']
			possible_end_date_fields = ['origin_info_date_issued_end_ssm', 'origin_info_date_created_end_ssm', 'origin_info_date_other_end_ssm']
			start_date = nil
			end_date = nil
			start_year = nil
			end_year = nil
			possible_start_date_fields.each{|key|
				if solr_doc.has_key?(key)
						start_date = solr_doc[key][0]
					break
				end
			}
			possible_end_date_fields.each{|key|
				if solr_doc.has_key?(key)
						end_date = solr_doc[key][0]
					break
				end
			}

			if start_date.present?

				end_date = start_date if end_date.blank?

				year_regex = /^(-?\d{1,4}).*/

				start_year_match = start_date.match(year_regex)
				start_year = start_year_match.captures[0] if start_year_match
				start_year = zero_pad_year(start_year)
				solr_doc["lib_start_date_year_itsi"] = start_year.to_i if start_year # TrieInt version for searches

				end_year_match = end_date.match(year_regex)
				end_year = end_year_match.captures[0] if end_year_match
				end_year = zero_pad_year(end_year)
				solr_doc["lib_end_date_year_itsi"] = end_year.to_i  if end_year # TrieInt version for searches

				solr_doc["lib_date_year_range_si"] = start_year + '-' + end_year if start_year

				# When no textual date is available, fall back to other date data (if available)
				if solr_doc["lib_date_textual_ssm"].blank?

					solr_doc["lib_date_textual_ssm"] = date_range_to_textual_date(start_year.to_i, end_year.to_i)
				end
			end

      solr_doc.each do |k, v|
        if self.class.maps_field? k
          solr_doc[k] = self.class.map_value(k, v)
        end
      end
      solr_doc
    end

    def zero_pad_year(year)
			year = year.to_s
			is_negative = year.start_with?('-')
			year_without_sign = (is_negative ? year[1, year.length]: year)
			if year_without_sign.length < 4
				year_without_sign = year_without_sign.rjust(4, '0')
			end

			return (is_negative ? '-' : '') + year_without_sign
		end

    def self.normalize(t, strip_punctuation=false)
      # strip whitespace
      n_t = t.dup.strip
      # collapse intermediate whitespace
      n_t.gsub!(/\s+/, ' ')
      # pull off paired punctuation, and any leading punctuation
      if strip_punctuation
        n_t = n_t.sub(/^\((.*)\)$/, "\\1")
        n_t = n_t.sub(/^\{(.*)\}$/, "\\1")
        n_t = n_t.sub(/^\[(.*)\]$/, "\\1")
        n_t = n_t.sub(/^"(.*)"$/, "\\1")
        n_t = n_t.sub(/^'(.*)'$/, "\\1")
        n_t = n_t.sub(/^<(.*)>$/, "\\1")
        #n_t = n_t.sub(/^\p{Ps}(.*)\p{Pe}/u, "\\1")
        n_t = n_t.sub(/^[[:punct:]]+/, '')
        # this may have 'created' leading/trailing space, so strip
        n_t.strip!
      end
      n_t
    end
  end
end
