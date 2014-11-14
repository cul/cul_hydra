# -*- encoding: utf-8 -*-
require 'rdf'
module RDF
  class SC < RDF::StrictVocabulary("http://www.shared-canvas.org/ns/")
    term :Manifest,
      type: "rdfs:Class".freeze
    term :Sequence,
      type: "rdfs:Class".freeze
    term :Canvas,
      type: "rdfs:Class".freeze
    # IIIF 'attribution'
    property :attributionLabel
    # IIIF 'service'
    property :hasRelatedService
    # IIIF 'seeAlso'
    property :hasRelatedDescription
    # IIIF 'sequences'
    # range is a collection of Sequence
    property :hasSequences

    property :withinManifest,
      range: "http://www.shared-canvas.org/ns/Manifest".freeze,
      subPropertyOf: "dc:isPartOf".freeze
    property :withinSequence,
      range: "http://www.shared-canvas.org/ns/Sequence".freeze,
      subPropertyOf: "dc:isPartOf".freeze

    # IIIF 'canvases'
    # range is a collection of Canvas
    property :hasCanvases
    # IIIF 'resources'
    property :hasAnnotations
    # IIIF 'images'
    property :hasImageAnnotations
    # IIIF 'otherContent'
    property :hasLists
    # IIIF 'structures'
    property :hasRanges
    # IIIF 'metadata'
    # range is a collection of Resource
    property :metadataLabels
    # IIIF 'viewingDirection'
    property :viewingDirection
    # IIIF 'viewingHint'
    property :viewingHint
  end
end