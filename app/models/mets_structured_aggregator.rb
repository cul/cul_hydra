require "active-fedora"
require "active_fedora_finders"
class METSStructuredAggregator < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::FinderMethods::RepositoryMethods
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Hydra::Models::Common
  include Cul::Hydra::Models::Aggregator

  has_many :parts, :property => :cul_member_of, :class_name=>'ActiveFedora::Base'

  #alias :file_objects :resources

  def route_as
    "multipartitem"
  end
end
