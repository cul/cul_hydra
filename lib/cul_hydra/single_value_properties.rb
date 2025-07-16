require 'active_support/core_ext/hash'
require 'cul_hydra/single_value_properties/property_builder'
require 'cul_hydra/single_value_properties/term'
module Cul::Hydra
  ##
  # Implements property configuration common to Rdf::Resource,
  # RDFDatastream, and others.  It does its work at the class level,
  # and is meant to be extended.
  #
  # Define properties at the class level with:
  #
  #    property :title, predicate: RDF::DC.title, class_name: ResourceClass
  #
  module SingleValueProperties
    extend ActiveSupport::Concern
    autoload :PropertyBuilder, 'cul_hydra/single_value_properties/property_builder'
    autoload :Term, 'cul_hydra/single_value_properties/term'

    def get_term(args)
      @term_cache ||= {}
      single_value = self.class.reflect_on_property(args.first)&.instance_variable_get(:@single_value)
      term_class = single_value ? SingleValueProperties::Term : ActiveTriples::Term
      term = term_class.new(self, args)
      term_key = "#{term.send(:rdf_subject)}/#{term.property}/#{term.term_args}"
      @term_cache[term_key] ||= term
      @term_cache[term_key]
    end

    module ClassMethods
      ##
      # @note This method will delete existing statements with the correct subject and predicate from the graph
      def set_single_value(*args)
        # Add support for legacy 3-parameter syntax
        if args.length > 3 || args.length < 2
          raise ArgumentError, "wrong number of arguments (#{args.length} for 2-3)"
        end
        values = args.pop
        get_single_value_term(args).set(values)
      end

      ##
      # Registers properties for Resource-like classes
      # @param [Symbol]  name of the property (and its accessor methods)
      # @param [Hash]  opts for this property, must include a :predicate
      # @yield [index] index sets solr behaviors for the property
      def single_value_property(name, opts={}, &block)
        raise ArgumentError, "#{name} is a keyword and not an acceptable property name." if protected_property_name? name
        reflection = SingleValueProperties::PropertyBuilder.build(self, name, opts, &block)
        ActiveTriples::Reflection.add_reflection self, name, reflection
      end
    end
  end
end
