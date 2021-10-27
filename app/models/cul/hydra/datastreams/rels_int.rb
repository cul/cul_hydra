# -*- encoding : utf-8 -*-
require 'active-fedora'
require 'rdf/rdfxml'
module Cul
module Hydra
  module Datastreams
    class RelsInt < ActiveFedora::Datastream
      XSD_INT_BITLENGTH = 31
      class_attribute :profile_solr_name
      attr_accessor :relationships_loaded

      self.profile_solr_name = ActiveFedora::SolrService.solr_name("rels_int_profile", :stored_searchable)

      def serialize!
        self.content = to_rels_int() if changed_attributes.include? 'relationships'
        clear_attribute_changes ['relationships']
      end

      def relationships_will_change!
        attribute_will_change!('relationships')
      end

      def content
        if self.new? and @content.nil?
          content= RelsInt.xml_template
        else
          super
        end
      end

      def content= new_content
        super
        relationships_loaded=false
        load_relationships
      end

      def to_resource(object, literal=false)
        if object.is_a? ActiveFedora::Datastream
          ::RDF::URI.new("info:fedora/#{object.pid}/#{object.dsid}")
        elsif object.respond_to? :internal_uri
          ::RDF::URI.new(object.internal_uri)
        elsif object.is_a? ::RDF::Resource
          object
        elsif literal
          result = ::RDF::Literal.new(object)
          case # invalid datatypes for FCRepo 3
          when result.datatype.eql?(::RDF::XSD.integer)
            result.datatype = (signed_bit_length(result.object) > XSD_INT_BITLENGTH ? ::RDF::XSD.long : ::RDF::XSD.int)
          when result.datatype.eql?(::RDF::XSD.decimal)
            result.datatype = ::RDF::XSD.double
          when result.datatype.eql?(::RDF::XSD.boolean)
            result.datatype = nil
          when result.datatype.eql?(::RDF::XSD.date)
            result = ::RDF::Literal.new(object.to_datetime)
          when result.datatype.eql?(::RDF::XSD.time)
            result = ::RDF::Literal.new(object.to_datetime)
          end
          result
        else
          ::RDF::URI.new(object.to_s)
        end
      end

      def to_predicate(arg)
        return :p if arg.nil?
        if arg.is_a? Symbol
          arg = ActiveFedora::Predicates.find_graph_predicate(arg)
        elsif arg.is_a? ::RDF::Resource
          arg
        else
          ::RDF::URI.new(arg.to_s)
        end
      end

      def build_statement(datastream, predicate, object, literal=false)
        subject = to_resource(datastream)
        predicate = to_predicate(predicate)
        object = to_resource(object,literal)
        ::RDF::Statement.new(subject,predicate,object)
      end

      def add_relationship(datastream, predicate, target, literal=false)
        stmt = build_statement(datastream, predicate, target, literal)
        graph.insert(stmt) unless graph.has_statement? stmt
        relationships_will_change!
      end

      def remove_relationship(datastream, predicate, target, literal=false)
        stmt = build_statement(datastream, predicate, target, literal)
        graph.delete(stmt)
        relationships_will_change!
      end

      def clear_relationship(datastream, predicate)
        graph.delete [to_resource(datastream), to_predicate(predicate), nil]
        relationships_will_change!
      end

      def relationships(*args)
        q_args = args.empty? ? [:s, :p, :o] : [to_resource(args.first), to_predicate(args[1]), (args[2] || :o)]
        query = ::RDF::Query.new do |query|
          query << q_args
        end
        query.execute(graph).map(&:to_hash).map do |hash|
          stmt = q_args.map {|k| hash[k] || k}
          ::RDF::Statement.new(*stmt)
        end
      end

      def load_relationships
        # load from content
        g = ::RDF::Graph.new
        ::RDF::RDFXML::Reader.new(content).each do |stmt|
          g << stmt
        end
        self.relationships_loaded = true
        clear_attribute_changes ['relationships']
        @graph = g
      end

      def graph
        @graph ||= load_relationships
      end

      def to_rels_int
        xml = Cul::Hydra::RelsInt::RDFXMLWriter.buffer(:max_depth=>1) do |writer|
          graph.each_statement do |statement|
            writer << statement
          end
        end
        xml
      end

      def self.xml_template
        "<rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"></rdf:RDF>"
      end

      def to_solr(solr_doc=Hash.new)
        result = super(solr_doc)
        result = solrize_relationships(result)
        result
      end

      def from_solr(solr_doc)
        predicate_symbol = self.profile_solr_name
        value = (solr_doc[predicate_symbol].nil? ? solr_doc[predicate_symbol.to_s]: solr_doc[predicate_symbol])
        @solr_hash = value.blank? ? nil : JSON.parse(value[0])
      end

      def solrize_relationships(solr_doc=Hash.new)
        rel_hash = {} # the rels_int_profile is a hash of hashes in json
        graph.each_statement do |statement|
          predicate = ActiveFedora::Predicates.short_predicate(statement.predicate)
          literal = statement.object.kind_of?(::RDF::Literal)
          val = literal ? statement.object.value : statement.object.to_str
          rel_hash[statement.subject] ||= {}
          rel_hash[statement.subject][predicate] ||= []
          rel_hash[statement.subject][predicate] << val
        end
        solr_doc[self.class.profile_solr_name] = rel_hash.to_json unless rel_hash.blank?
        solr_doc
      end
      class UriObject
        def initialize(resource)
          @resource = resource
        end
      end
      private
      def signed_bit_length(num)
        if num.respond_to? :bit_length
          num.bit_length
        else # in MRI 1.9.x, we need to implement the two complement bitlength
          Math.log2(num < 0 ? num.abs : num+1).ceil
        end
      end
    end
  end
end
end
