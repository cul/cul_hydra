# -*- encoding: utf-8 -*-
# This file generated automatically using vocab-fetch from http://purl.org/ontology/olo/core#
require 'rdf'
module RDF
  class OLO < RDF::StrictVocabulary("http://purl.org/ontology/olo/core#")

    # Class definitions
    term :OrderedList,
      comment: %(An ordered list with a given length an indexed items.).freeze,
      label: "Ordered List".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      subClassOf: "owl:Thing".freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze],
      "vs:status" => %(stable).freeze
    term :Slot,
      comment: %(A slot in an ordered list with a fixed index.).freeze,
      label: "Slot".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      subClassOf: "owl:Thing".freeze,
      type: ["owl:Class".freeze, "rdfs:Class".freeze],
      "vs:status" => %(stable).freeze

    # Property definitions
    property :index,
      comment: %(An index of a slot in an ordered list.).freeze,
      domain: "http://purl.org/ontology/olo/core#Slot".freeze,
      label: "has index".freeze,
      range: "xsd:positiveInteger".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      type: ["owl:DatatypeProperty".freeze, "rdf:Property".freeze, "owl:FunctionalProperty".freeze],
      "vs:status" => %(stable).freeze
    property :item,
      comment: %(An item of a slot in an ordered list.).freeze,
      domain: "http://purl.org/ontology/olo/core#Slot".freeze,
      label: "has item".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      type: "rdf:Property".freeze,
      "vs:status" => %(stable).freeze
    property :length,
      comment: %(The length of an ordered list.).freeze,
      domain: "http://purl.org/ontology/olo/core#OrderedList".freeze,
      label: "has length".freeze,
      range: "xsd:nonNegativeInteger".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      type: ["owl:DatatypeProperty".freeze, "rdf:Property".freeze, "owl:FunctionalProperty".freeze],
      "vs:status" => %(stable).freeze
    property :next,
      comment: %(Associates the next slot in an ordered list.).freeze,
      domain: "http://purl.org/ontology/olo/core#Slot".freeze,
      label: "has next".freeze,
      range: "http://purl.org/ontology/olo/core#Slot".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      type: ["rdf:Property".freeze, "owl:FunctionalProperty".freeze],
      "vs:status" => %(testing).freeze
    property :ordered_list,
      comment: %(An ordered list of an slot.).freeze,
      domain: "http://purl.org/ontology/olo/core#Slot".freeze,
      label: "has ordered list".freeze,
      "owl:inverseOf" => %(http://purl.org/ontology/olo/core#slot).freeze,
      range: "http://purl.org/ontology/olo/core#OrderedList".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      type: ["rdf:Property".freeze, "owl:FunctionalProperty".freeze],
      "vs:status" => %(testing).freeze
    property :previous,
      comment: %(Associates the previous slot in an ordered list).freeze,
      domain: "http://purl.org/ontology/olo/core#Slot".freeze,
      label: "has previous".freeze,
      "owl:inverseOf" => %(http://purl.org/ontology/olo/core#next).freeze,
      range: "http://purl.org/ontology/olo/core#Slot".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      type: ["owl:InverseFunctionalProperty".freeze, "rdf:Property".freeze],
      "vs:status" => %(testing).freeze
    property :slot,
      comment: %(A slot in an ordered list.).freeze,
      domain: "http://purl.org/ontology/olo/core#OrderedList".freeze,
      label: "has slot".freeze,
      range: "http://purl.org/ontology/olo/core#Slot".freeze,
      "rdfs:isDefinedBy" => %(http://purl.org/ontology/olo/core#).freeze,
      type: ["owl:ObjectProperty".freeze, "rdf:Property".freeze],
      "vs:status" => %(stable).freeze

    # Extra definitions
    term :"",
      "dc11:creator" => [%(http://www.elec.qmul.ac.uk/people/samer/).freeze, %(http://foaf.me/zazi#me).freeze],
      "dc11:date" => %(2010-07-23T13:30:52+01:00).freeze,
      "dc11:description" => %(
The <em xmlns="http://www.w3.org/1999/xhtml" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:vs="http://www.w3.org/2003/06/sw-vocab-status/ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:olo="http://purl.org/ontology/olo/core#" xmlns:vann="http://purl.org/vocab/vann/" xmlns:bibo="http://purl.org/ontology/bibo/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xml:lang="en">Ordered List Ontology Specification</em> provides basic concepts and properties 
for describing ordered lists as semantic graph. This document contains a RDFa description of the <em xmlns="http://www.w3.org/1999/xhtml" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:vs="http://www.w3.org/2003/06/sw-vocab-status/ns#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:olo="http://purl.org/ontology/olo/core#" xmlns:vann="http://purl.org/vocab/vann/" xmlns:bibo="http://purl.org/ontology/bibo/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#" xml:lang="en">Ordered List Ontology</em>
as proposed by Samer A. Abdallah and some additional information and examples.
).freeze,
      "dc11:rights" => %(Copyright © 2010 Samer A. Abdallah and Bob Ferris).freeze,
      "dc11:title" => %(The Ordered List Ontology).freeze,
      "foaf:isPrimaryTopicOf" => %(http://purl.org/ontology/olo/orderedlistontology.html).freeze,
      "http://purl.org/vocab/vann/preferredNamespaceUri" => %(http://purl.org/ontology/olo/core#).freeze,
      label: "".freeze,
      "owl:versionInfo" => %(0.72).freeze,
      "rdfs:seeAlso" => [%(http://smiy.sourceforge.net/olo/gfx/olo_-_orderedlist.gif).freeze, %(http://www.w3.org/TR/2004/REC-owl-ref-20040210/#Class).freeze],
      type: "owl:Ontology".freeze
  end
end
