require "rubygems"
module Cul
  module Scv
    module Hydra
    end
  end
end
# this is a hack to make requiring hydra possible
module Hydra
  module Datastream
    module CommonModsIndexMethods
    end
  end
end
require 'hydra'
require "cul_scv_hydra/access_controls_enforcement"
require "cul_scv_hydra/active_fedora"
require "cul_scv_hydra/controllers"
require "cul_scv_hydra/om"
require "cul_scv_hydra/solrizer"
require "cul_scv_hydra/version"
require "cul_scv_hydra/engine" if defined? Rails
