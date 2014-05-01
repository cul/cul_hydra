require "active-fedora"
require "active_fedora_finders"
class GenericObject < ::ActiveFedora::Base
  extend ActiveModel::Callbacks
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::Models::Common
  include Cul::Scv::Hydra::Models::Aggregator

  has_many :parts, :property => :cul_member_of, :class_name=>'ActiveFedora::Base'

  #alias :file_objects :resources

  def route_as
    "multipartitem"
  end
end
