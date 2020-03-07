# -*- encoding : utf-8 -*-
require 'active_fedora/rdf_xml_writer'
module Cul
module Hydra
  module RelsInt
    class RDFXMLWriter < ActiveFedora::RDFXMLWriter
      # Write a predicate with one or more values.
      #
      # Values may be a combination of Literal and Resource (Node or URI).
      # @param [RDF::Resource] predicate
      #   Predicate to serialize
      # @param [Array<RDF::Resource>] objects
      #   Objects to serialize
      # @return [String]
      def predicate(predicate, objects)
        add_debug {"predicate: #{predicate.inspect}, objects: #{objects}"}

        return if objects.to_a.empty?

        add_debug {"predicate: #{get_curie(predicate)}"}
        render_property(predicate, objects) do |o, inlist=nil|
          # Yields each object, for potential recursive definition.
          # If nil is returned, a leaf is produced
          #depth {subject(o, :rel => get_curie(predicate), :inlist => inlist, :element => (:li if objects.length > 1 || inlist))} if !is_done?(o) && @subjects.include?(o)
          # we don't ever want to recurse, so nil it all
          nil
        end
      end

    end
  end
end
end