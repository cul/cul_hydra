# -*- encoding: utf-8 -*-
# This file generated automatically using vocab-fetch from github.com:fcrepo3/fcrepo/master/fcrepo-server/src/main/resources/rdfs/fedora_relsext_ontology.rdfs
# and edited for clarity and additional terms published in different serializations of the voabularies
require 'rdf'
module RDF
  module FCREPO3
    class SYSTEM < RDF::StrictVocabulary("info:fedora/fedora-system:")
      term :"FedoraObject-3.0",
        comment: %(Base Fedora 3 Object cModel).freeze,
        label: "Fedora 3 Object".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "rdfs:Class".freeze
      term :"ServiceDefinition-3.0",
        comment: %(Fedora 3 Service Definition/BDef cModel).freeze,
        label: "Fedora 3 Service Definition".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "rdfs:Class".freeze
      term :"ServiceDeployment-3.0",
        comment: %(Fedora 3 Service Deployment/BMech cModel).freeze,
        label: "Fedora 3 Service Deployment".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "rdfs:Class".freeze
    end
    class MODEL < RDF::StrictVocabulary("info:fedora/fedora-system:def/model#")
      # Class definitions
      term :FedoraObject,
        comment: %().freeze,
        label: "".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "rdfs:Class".freeze
      term :State,
        comment: %().freeze,
        label: "".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "rdfs:Class".freeze
      term :Active,
        comment: %().freeze,
        label: "".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "info:fedora/fedora-system:def/model#State".freeze
      term :Deleted,
        comment: %().freeze,
        label: "".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "info:fedora/fedora-system:def/model#State".freeze
      term :Inactive,
        comment: %().freeze,
        label: "".freeze,
        subClassOf: "rdfs:Resource".freeze,
        type: "info:fedora/fedora-system:def/model#State".freeze
      # Property definitions
      property :altIds,
        comment: %(The alternate IDs for a datastream).freeze,
        label: "Alternate IDs".freeze,
        type: "rdf:Property".freeze
      property :controlGroup,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :createdDate,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :definesMethod,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :digest,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :digestType,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :downloadFilename,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :extProperty,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :formatURI,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :hasModel,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :hasService,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :isContractorOf,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :isDeploymentOf,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :label,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :length,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :ownerId,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :state,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :versionable,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
    end
    class RELSEXT < RDF::StrictVocabulary("info:fedora/fedora-system:def/relations-external#")

      # Property definitions
      property :fedoraRelationship,
        comment: %(The primitive property for all object-to-object relationships in the fedora ontology).freeze,
        label: "Fedora Relationship".freeze,
        type: "rdf:Property".freeze
      property :hasAnnotation,
        comment: %(A refinement of the generic descriptive relationship indicating a commentary relationship between fedora objects.  The subject is a fedora object that is being commented on and the predicate is a fedora object that represents an annotation or comment about the subject. ).freeze,
        label: "Has Annotation".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasDescription".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isAnnotationOf).freeze,
        type: "rdf:Property".freeze
      property :hasCollectionMember,
        label: "Has Collection Member".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasMember".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMemberOfCollection).freeze,
        type: "rdf:Property".freeze
      property :hasConstituent,
        label: "Has Constituent".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasPart".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isConstituentOf).freeze,
        type: "rdf:Property".freeze
      property :hasDependent,
        label: "Has Dependent".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDependentOf).freeze,
        type: "rdf:Property".freeze
      property :hasDerivation,
        label: "Has Derivation".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDerivationOf).freeze,
        type: "rdf:Property".freeze
      property :hasDescription,
        comment: %(A generic descriptive relationship between fedora objects.  The subject is a fedora object that is being described in some manner and the predicate is a fedora object that represents a descriptive entity that is about the subject. ).freeze,
        label: "Has Description".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isDescriptionOf).freeze,
        type: "rdf:Property".freeze
      property :hasEquivalent,
        label: "Has Equivalent".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        type: "rdf:Property".freeze
      property :hasMember,
        label: "Has Member".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasPart/".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMemberOf).freeze,
        type: "rdf:Property".freeze
      property :hasMetadata,
        comment: %(A refinement of the generic descriptive relationship indicating a metadata relationship between fedora objects.  The subject is a fedora object and the predicate is a fedora object that represents metadata about the subject. ).freeze,
        label: "Has Metadata".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasDescription".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isMetadataFor).freeze,
        type: "rdf:Property".freeze
      property :hasPart,
        label: "Has Part".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isPartOf).freeze,
        type: "rdf:Property".freeze
      property :hasSubset,
        label: "Has Subset".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#hasMember".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#isSubsetOf).freeze,
        type: "rdf:Property".freeze
      property :isAnnotationOf,
        comment: %(A refinement of the generic descriptive relationship indicating a commentary relationship between fedora objects.  The subject is a fedora object that represents an annotation or comment and the predicate is a fedora object that is being commented upon by the subject.).freeze,
        label: "Is Annotation Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#isDescriptionOf".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasAnnotation).freeze,
        type: "rdf:Property".freeze
      property :isConstituentOf,
        label: "Is Constituent Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#isPartOf".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasConstituent).freeze,
        type: "rdf:Property".freeze
      property :isDependentOf,
        label: "Is Dependent Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDependent).freeze,
        type: "rdf:Property".freeze
      property :isDerivationOf,
        label: "Is Derivation Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDerivation).freeze,
        type: "rdf:Property".freeze
      property :isDescriptionOf,
        comment: %(A generic descriptive relationship between fedora objects.  The subject is a fedora object that represents a descriptive entity and the predicate is a fedora object that is being described in some manner by the subject.).freeze,
        label: "Is Description Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasDescription).freeze,
        type: "rdf:Property".freeze
      property :isMemberOf,
        label: "Is Member Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#isPartOf".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasMember).freeze,
        type: "rdf:Property".freeze
      property :isMemberOfCollection,
        label: "Is Member Of Collection".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasCollectionMember).freeze,
        type: "rdf:Property".freeze
      property :isMetadataFor,
        comment: %(A refinement of the generic descriptive relationship indicating a metadata relationship between fedora objects.  The subject is a fedora object that represents metadata and the predicate is a fedora object for which the subject serves as metadata.).freeze,
        label: "Is Metadata For".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#isDescriptionOf".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasMetadata).freeze,
        type: "rdf:Property".freeze
      property :isPartOf,
        label: "Is Part Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#fedoraRelationship".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasPart).freeze,
        type: "rdf:Property".freeze
      property :isSubsetOf,
        label: "Is Subset Of".freeze,
        subPropertyOf: "info:fedora/fedora-system:def/relations-external#isMemberOf".freeze,
        "owl:inverseOf" => %(info:fedora/fedora-system:def/relations-external#hasSubset).freeze,
        type: "rdf:Property".freeze
    end
    class VIEW < RDF::StrictVocabulary("info:fedora/fedora-system:def/view#")
      property :disseminates,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze      
      property :disseminationType,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :isVolatile,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :lastModifiedDate,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :mimeType,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :version,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
    end
  end
  class MULGARA < RDF::StrictVocabulary("http://mulgara.org/mulgara#")
      property :after,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze      
      property :before,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :gt,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :lt,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :is,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :notOccurs,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :occursLessThan,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
      property :occursMoreThan,
        comment: %().freeze,
        label: "".freeze,
        type: "rdf:Property".freeze
    end
end
