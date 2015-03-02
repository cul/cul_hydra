module Cul::Hydra::Controller

  def asset_path_from_config(asset)
    Rails.configuration.assets.paths.each do |dir|
      result = "#{dir}/#{asset}"
      return result if File.exists?(result)
    end
    return nil
  end

  def asset_url(source)
    URI.join(root_url, ActionController::Base.helpers.asset_path(source))
  end

  def http_client
    unless @http_client
      @http_client ||= HTTPClient.new
    end
    @http_client
  end

end