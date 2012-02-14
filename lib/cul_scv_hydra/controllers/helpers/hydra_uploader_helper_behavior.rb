module Cul::Scv::Hydra::Controllers::Helpers
module HydraUploaderHelperBehavior
  
  # Generate the appropriate url for posting uploads to
  # Uses the +container_id+ method to figure out what container uploads should go into
  def upload_url(in_place=false)
    if in_place
      upload_url = asset_datastream_path(:asset_id=>container_id, :id=>'CONTENT')
    else
      upload_url = asset_resources_path(:container_id=>container_id)
    end
  end
  
  def asset_id
    if !params[:asset_id].nil?
      return params[:asset_id]
    else
      return params[:id]
    end
  end

  # The id of the container that uploads should be posted into
  # If params[:container_id] is not set, it uses params[:id] (assumes that you're uploading items into the current object)
  def container_id
    if !params[:container_id].nil?
      return params[:container_id]
    elsif !params[:asset_id].nil?
      return params[:asset_id]
    else
      return params[:id]
    end
  end
end
end
