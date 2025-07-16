require 'active_support/core_ext/module/delegation'

module Cul::Hydra::SingleValueProperties
  class Term < ActiveTriples::Term

    def result
      _r = parent.query(:subject => rdf_subject, :predicate => predicate)
        .each_with_object([]) do |x, collector|
          converted_object = convert_object(x.object)
          collector << converted_object unless converted_object.nil?
        end
      _r.first
    end

    def set(values)
      values = [values].compact unless values.kind_of?(Array)
      values = values.to_a if ActiveTriples::Term === values
      empty_property
      set_value(values.first)
      parent.persist! if parent.class.repository == :parent && parent.send(:repository)
    end

    def << (values)
      self.set(Array(values).first)
    end

    alias_method :push, :<<
  end
end
