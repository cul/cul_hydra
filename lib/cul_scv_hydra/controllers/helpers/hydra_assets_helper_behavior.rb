require 'mediashelf/active_fedora_helper'

module Cul::Scv::Hydra::Helpers::HydraAssetsHelperBehavior
  include MediaShelf::ActiveFedoraHelper

  def link_to_create_asset(link_label, content_type, container_id=nil)
    opts = {:action => 'new', :controller => "#{content_type}s", :content_type => content_type}
    opts[:container_id] = container_id unless container_id.nil?
    if current_user
      link_to link_label, opts, :class=>"create_asset"
    else      
      link_to link_label, {:action => 'new', :controller => 'user_sessions', :redirect_params => opts}, :class=>"create_asset"
    end
  end

  def get_file_asset_description(document)
    obj = load_af_instance_from_solr(document)
    if obj.nil? || obj.file_objects.empty?
      return ""
    else
       fobj = Cul::Model::Core::Resource.load_instance_from_solr(obj.file_objects.first.pid)
       fad = ""
       unless fobj.nil?
         unless fobj.datastreams["descMetadata"].nil?
           fad = short_description(fobj.datastreams["descMetadata"].get_values("description").first)
         else
           fad = short_description(fobj.datastreams["DC"].get_values("description").first)
         end
       end
       fad
    end
  end

  def apply_depositor_metadata(user, is_public=false)
    if self.is_a? ActiveFedora::Base 
      rights_md = self.datastreams['rightsMetadata']
      if rights_md
        rights_md.permissions({"person"=>user}, "edit")
        rights_md.permissions({"person"=>user}, "read")
        if is_public
          rights_md.permissions({"group"=>"public"}, "read")
        end
      end
    end
  end
end
