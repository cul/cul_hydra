module RDF
  class CUL < RDF::StrictVocabulary("http://purl.oclc.org/NET/CUL/")
    term :Aggregator,
      comment: %(An collection of Aggregators or Resources).freeze,
      label: "Aggregator".freeze,
      type: "rdfs:Class".freeze
    term :Resource,
      comment: %(A file-like Resource).freeze,
      label: "Resource".freeze,
      type: "rdfs:Class".freeze
    property :hasMember,
      comment: %(The object is a member of the subject Aggregator.).freeze,
      domain: "http://purl.oclc.org/NET/CUL/Aggregator".freeze,
      label: "hasMember".freeze,
      range: ["http://purl.oclc.org/NET/CUL/Aggregator".freeze,"http://purl.oclc.org/NET/CUL/Resource".freeze],
      subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasMember".freeze,
      type: "rdf:Property".freeze
    property :memberOf,
      comment: %(The subject is a member of the object Aggregator.).freeze,
      domain: ["http://purl.oclc.org/NET/CUL/Aggregator".freeze,"http://purl.oclc.org/NET/CUL/Resource".freeze],
      label: "memberOf".freeze,
      range: "http://purl.oclc.org/NET/CUL/Aggregator".freeze,
      subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf".freeze,
      type: "rdf:Property".freeze
    property :obsoleteFrom,
      comment: %(The subject is an obsolete member of the object Aggregator.).freeze,
      domain: ["http://purl.oclc.org/NET/CUL/Aggregator".freeze,"http://purl.oclc.org/NET/CUL/Resource".freeze],
      label: "obsoleteFrom".freeze,
      range: "http://purl.oclc.org/NET/CUL/Aggregator".freeze,
      subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf".freeze,
      type: "rdf:Property".freeze
    property :metadataFor,
      comment: %(The subject is an obsolete description of the object.).freeze,
      domain: ["http://purl.oclc.org/NET/CUL/Aggregator".freeze,"http://purl.oclc.org/NET/CUL/Resource".freeze],
      label: "metadataFor".freeze,
      range: "http://purl.oclc.org/NET/CUL/Aggregator".freeze,
      subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMetadataFor".freeze,
      type: "rdf:Property".freeze
    module RESOURCE
      module STILLIMAGE
        class BASIC < RDF::StrictVocabulary("http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/")
          property :imageWidth,
            label: "imageWidth",
            type: "rdf:Property".freeze
          property :imageLength,
            label: "imageLength",
            type: "rdf:Property".freeze
        end
        class ASSESSMENT < RDF::StrictVocabulary("http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/ASSESSMENT/")
          property :xSamplingFrequency,
            label: "xSamplingFrequency",
            type: "rdf:Property".freeze
          property :ySamplingFrequency,
            label: "ySamplingFrequency",
            type: "rdf:Property".freeze
          property :samplingFrequencyUnit,
            label: "samplingFrequencyUnit",
            type: "rdf:Property".freeze
        end
      end
    end
    # An addition to FOAF used locally at CUL
    class FOAF < RDF::StrictVocabulary("http://xmlns.com/foaf/0.1/")
      property :zoomingImage,
      comment: %(A derived zoomable image.).freeze,
      domain: "foaf:Image".freeze,
      label: "zoomingImage".freeze,
      range: "foaf:Image".freeze,
      "rdfs:isDefinedBy" => %(foaf:).freeze,
      type: ["rdf:Property".freeze, "owl:ObjectProperty".freeze],
      "vs:term_status" => %(testing).freeze
    end
  end
end