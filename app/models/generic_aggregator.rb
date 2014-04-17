require "active-fedora"
require "active_fedora_finders"
class GenericAggregator < ::ActiveFedora::Base
  include ::ActiveFedora::Finders
  include ::ActiveFedora::DatastreamCollections
  include ::Hydra::ModelMethods
  include Cul::Scv::Hydra::Models::Common
  include Cul::Scv::Hydra::Models::Aggregator

  has_many :parts, :property => :cul_member_of, :class_name=>'ActiveFedora::Base'

  def route_as
    "multipartitem"
  end

  def index_type_label
    riquery = Cul::Scv::Hydra::Models::MEMBER_ITQL.gsub(/%PID%/, self.pid)
    begin
      docs = Cul::Scv::Fedora.repository.find_by_itql riquery, limit: 2, format: json
      docs = JSON.parse(docs)['results']
    rescue Exception=>e
      Rails.logger.warn("#{self.class.name} failed to find children with TQL: #{e.message}")
      docs = self.parts
    end
    if docs.size == 0
      label = "EMPTY"
    elsif docs.size == 1
      label = "SINGLE PART"
    else
      label = "MULTIPART"
    end
    label
  end

end