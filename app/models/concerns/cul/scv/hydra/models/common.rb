require 'active-fedora'
require 'uri'
module Cul::Scv::Hydra::Models::Common
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::Models::Common
  end
end
