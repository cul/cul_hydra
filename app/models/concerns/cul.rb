module Cul
	extend ActiveSupport::Autoload
  autoload :'Scv::Hydra::Models', 'cul/scv/hydra/models'
  autoload :'Scv::Hydra::Models::Common', 'cul/scv/hydra/models/common'
  autoload :'Scv::Hydra::Models::Aggregator', 'cul/scv/hydra/models/aggregator'
  autoload :'Scv::Hydra::Models::Resource', 'cul/scv/hydra/models/resource'
end
