module Pcdm::Models
  extend ActiveSupport::Concern
  module ClassMethods
    def to_class_uri
      "info:fedora/pcdm:#{self.name.split('::').last}"
    end
  end
end