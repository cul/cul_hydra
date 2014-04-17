require "active-fedora"
require "cul_scv_hydra/om"
require 'uri'
require 'rdf'
module Cul
module Scv
module Hydra
  module Models
    AGGREGATOR_TYPE = (URI.parse("http://purl.oclc.org/NET/CUL/Aggregator"))
    RESOURCE_TYPE = (URI.parse("http://purl.oclc.org/NET/CUL/Resource"))
    MEMBER_QUERY = <<-SPARQL
      SELECT ?pid WHERE { ?pid <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/%PID%> }
    SPARQL
  end
end
end
end