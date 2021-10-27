module Cul::Hydra::Controller

  def asset_url(source)
    URI.join(root_url, ActionController::Base.helpers.asset_path(source))
  end

  def http_client
    @http_client ||= HTTPClient.new
  end
end
