module Cul::Scv::Hydra::Indexer
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Indexer
  end
end
