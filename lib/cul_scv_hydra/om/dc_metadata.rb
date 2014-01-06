require 'active-fedora'
module Cul
module Scv
module Hydra
module Om
  class DCMetadata < ::ActiveFedora::OmDatastream

    after_save :action_after_save
    set_terminology do |t|
      t.root(:path=>"dc", :namespace_prefix=>"oai_dc",
             "xmlns:oai_dc"=>"http://www.openarchives.org/OAI/2.0/oai_dc/",
             "xmlns:dc"=>"http://purl.org/dc/elements/1.1/",
             :schema=>"http://www.openarchives.org/OAI/2.0/oai_dc.xsd")
      t.dc_contributor(:path=>"contributor", 
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_coverage(:path=>"coverage",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_creator(:path=>"creator",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_date(:path=>"date",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_description(:path=>"description",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_format(:path=>"format",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_identifier(:path=>"identifier",
        :namespace_prefix=>"dc",
        :type=>:string,
        :index_as=>[:symbol])
      t.dc_language(:path=>"language",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_publisher(:path=>"publisher",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_relation(:path=>"relation",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_rights(:path=>"rights",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_source(:path=>"source",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_subject(:path=>"subject",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_title(:path=>"title",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
      t.dc_type(:path=>"type",
        :namespace_prefix=>"dc",
        :index_as=>[:displayable, :searchable])
    end
  
    def self.xml_template

      Nokogiri::XML::Document.parse(<<-src
<oai_dc:dc
      xmlns:oai_dc='http://www.openarchives.org/OAI/2.0/oai_dc/'
      xmlns:dc='http://purl.org/dc/elements/1.1/'
      xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
      xsi:schemaLocation='http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd'></oai_dc:dc>
src
)
    end
    # Because FCRepo 3.5+ modifies DC on saves (to ensure that PID is a dc:identifier value),
    # this datastream's content must be reloaded after saves
    def action_after_save
      @content = nil
      @ng_xml = nil
      remove_instance_variable(:@ng_xml)
    end

    def method_missing method, *args
      query = false
      _mname = method.id2name
      if _mname[-1,1] == '?'
        query = true
        _mname = _mname[0,_mname.length-1]
      end
      _msym = _mname.to_sym
      has_term = self.class.terminology.has_term?(_msym)
      return false if query and not has_term
      _r = super(_mname.to_sym, *args)
      if query
        _r.length > 0
      else
        _r
      end
    end
  end
end
end
end
end
