require "active-fedora"
require "active_fedora_finders"
class GenericAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::Models::Common
  include Cul::Scv::Hydra::Models::Aggregator

  alias :file_objects :resources

  def route_as
    "multipartitem"
  end
end