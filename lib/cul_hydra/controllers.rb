module Cul::Hydra
  module Controllers
    autoload :Aggregates, 'cul_hydra/controllers/aggregates'
    autoload :Catalog, 'cul_hydra/controllers/catalog'
    autoload :ContentAggregators, 'cul_hydra/controllers/content_aggregators'
    autoload :Datastreams, 'cul_hydra/controllers/datastreams'
    autoload :Helpers, 'cul_hydra/controllers/helpers'
    autoload :Resources, 'cul_hydra/controllers/resources'
    autoload :StaticImageAggregators, 'cul_hydra/controllers/static_image_aggregators'
    autoload :Suggestions, 'cul_hydra/controllers/suggestions'
    autoload :Terms, 'cul_hydra/controllers/terms'
  end
end
