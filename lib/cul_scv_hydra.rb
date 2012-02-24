require "rubygems"
module Cul
  module Scv
    module Hydra
    end
  end
end
require "cul_scv_hydra/access_controls_enforcement"
require "cul_scv_hydra/active_fedora"
require "cul_scv_hydra/controllers"
require "cul_scv_hydra/om"
require "cul_scv_hydra/solrizer"
require "cul_scv_hydra/version"
require "cul_scv_hydra/engine" if defined? Rails
