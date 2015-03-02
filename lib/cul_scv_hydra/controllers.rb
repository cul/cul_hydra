module Cul::Scv::Hydra
  module Controllers
    autoload :Aggregates, 'cul_scv_hydra/controllers/aggregates'
    autoload :Catalog, 'cul_scv_hydra/controllers/catalog'
    autoload :ContentAggregators, 'cul_scv_hydra/controllers/content_aggregators'
    autoload :Datastreams, 'cul_scv_hydra/controllers/datastreams'
    autoload :Helpers, 'cul_scv_hydra/controllers/helpers'
    autoload :Resources, 'cul_scv_hydra/controllers/resources'
    autoload :StaticImageAggregators, 'cul_scv_hydra/controllers/static_image_aggregators'
    autoload :Suggestions, 'cul_scv_hydra/controllers/suggestions'
    autoload :Terms, 'cul_scv_hydra/controllers/terms'
  end
end