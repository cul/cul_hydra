require "active-fedora"
require "cul_hydra/om"
require 'uri'
require 'rdf'
module Cul
module Hydra
  module Models
    AGGREGATOR_TYPE = RDF::Cul.Aggregator
    RESOURCE_TYPE = RDF::Cul.Resource
    MEMBER_OF = RDF::Cul.memberOf
    MEMBER_SPARQL = <<-SPARQL
      SELECT ?pid WHERE { ?pid <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/%PID%> }
    SPARQL
    MEMBER_ITQL = <<-ITQL
      select $pid from <#ri> where $pid <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/%PID%>
    ITQL
    autoload :Aggregator, 'cul/hydra/models/aggregator'
    autoload :Common, 'cul/hydra/models/common'
    autoload :ImageResource, 'cul/hydra/models/image_resource'
    autoload :RelsInt, 'cul/hydra/models/rels_int'
    autoload :Resource, 'cul/hydra/models/resource'
  end
end
end