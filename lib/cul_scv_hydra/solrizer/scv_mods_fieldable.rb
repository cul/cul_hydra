module Cul::Scv::Hydra::Solrizer
  module ScvModsFieldable
    extend ActiveSupport::Concern
    extend Cul::Hydra::Solrizer::ModsFieldable::ClassMethods
    included do
      include Cul::Hydra::Solrizer::ModsFieldable
    end
  end
end
