require 'cul_hydra/exceptions'
require 'cul_hydra/solrizer_patch'
module Cul
  module Hydra
    autoload :Fedora, 'cul_hydra/fedora'
    autoload :Om, 'cul_hydra/om'
    autoload :Solrizer, 'cul_hydra/solrizer'
    autoload :AccessLevels, 'cul_hydra/access_levels'
  end
end

require "cul_hydra/access_controls_enforcement"
require "cul_hydra/om"
require "cul_hydra/indexer"
require "cul_hydra/risearch_members"
require "cul_hydra/solrizer"
require "cul_hydra/rels_int"
require "cul_hydra/version"
require "cul_hydra/engine" if defined? Rails
