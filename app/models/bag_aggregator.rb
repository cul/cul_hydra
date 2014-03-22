require "active-fedora"
require "active_fedora_finders"
class BagAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::ActiveFedora::Model::Common
  include Cul::Scv::Hydra::ActiveFedora::Model::Aggregator

  alias :file_objects :resources

  def route_as
    "collection"
  end

  # Override update_index to do nothing so that we can use Fedora without needing a Solr index
  #def update_index
    # Do nothing!
  #end

end
