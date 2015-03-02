module Cul::Scv::Hydra::RisearchMembers
  extend ActiveSupport::Concern
  extend Cul::Hydra::RisearchMembers::ClassMethods
  included do
    include Cul::Hydra::RisearchMembers
  end
end
