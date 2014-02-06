module Cul::Scv::Hydra::Solrizer
	module ScvModsFieldable
    extend ActiveSupport::Concern

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
      node.xpath('./mods:titleInfo', MODS_NS).collect do |t|
        ScvModsFieldable.normalize(t.text)
      end
    end

    def names(role_authority=nil, role=nil)
      # get all the name nodes
      # reject the ones that aren't type 'personal' or 'corporate'
      # keep all child text except the role terms
      xpath = "./mods:name[@type = 'personal' or @type = 'corporate']"
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
      xpath = "./mods:subject" + xpath[1,xpath.length]
      mods.xpath(xpath, MODS_NS).each do |node|
        base_text = node.xpath('./mods:namePart', MODS_NS).collect { |c| c.text }.join(' ')
        names << ScvModsFieldable.normalize(base_text, true)
      end
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

    def repositories(node=mods)
      # get all the location/physicalLocation[@authority = 'marcorg']
      node.xpath("./mods:location/mods:physicalLocation[@authority = 'marcorg']", MODS_NS).collect do |n|
        ScvModsFieldable.normalize(n.text)
      end
    end

    def to_solr(solr_doc={})
      solr_doc = (defined? super) ? super : solr_doc
      solr_doc["title_si"] = sort_title
      solr_doc["title_ssm"] = titles
      solr_doc["lib_collection_sim"] = collections
      solr_doc["lib_project_sim"] = projects
      solr_doc["lib_name_sim"] = names
      solr_doc["lib_name_ssm"] = solr_doc["lib_name_sim"]
      solr_doc["lib_recipient_sim"] = names(:marcrelator, 'rcp')
      solr_doc["lib_format_sim"] = formats
      solr_doc["lib_repo_sim"] = repositories
      solr_doc.each do |k, v|
        if self.class.maps_field? k
          solr_doc[k] = self.class.map_value(k, v)
        end
      end
      solr_doc
    end

    def self.normalize(t, strip_punctuation=false)
      n_t = t.dup.strip
      if strip_punctuation
        n_t = n_t.sub(/^[[:punct:]]+/, '')
        n_t = n_t.sub(/[[:punct:]]+$/, '')
        n_t.strip!
      end
      n_t.gsub!(/\s+/, ' ')
      n_t
    end
  end
end