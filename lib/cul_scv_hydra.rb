require 'hydra/head'
require 'active_fedora_relsint'
require 'cul_hydra'
module Cul
  module Scv
    module Hydra
    end
    module Fedora
      extend Cul::Hydra::Fedora::ClassMethods
      autoload :DummyObject, 'cul_scv_fedora/dummy_object'
      autoload :RubydoraPatch, 'cul_scv_fedora/rubydora_patch'
      autoload :UrlHelperBehavior, 'cul_scv_fedora/url_helper_behavior'
    end
  end
end

require "cul_scv_hydra/access_controls_enforcement"
require "cul_scv_hydra/controllers"
require "cul_scv_hydra/om"
require "cul_scv_hydra/indexer"
require "cul_scv_hydra/risearch_members"
require "cul_scv_hydra/solrizer"
require "cul_scv_hydra/version"
require "cul_scv_hydra/engine" if defined? Rails
