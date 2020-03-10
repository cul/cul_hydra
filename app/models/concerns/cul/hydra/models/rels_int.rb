# -*- encoding : utf-8 -*-
require 'active_support'
module Cul::Hydra::Models
  module RelsInt
    extend ActiveSupport::Concern
    included do
      self.has_metadata :name=>"RELS-INT", :type=>Cul::Hydra::Datastreams::RelsInt
    end

    def rels_int
      if !datastreams.has_key?("RELS-INT")
        ds = Cul::Hydra::Datastreams::RelsInt.new(@inner_object, "RELS-INT")
        add_datastream(ds)
      end
      return datastreams["RELS-INT"]
    end
  end
end
