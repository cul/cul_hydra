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
    MEMBER_SPARQL = <<-SPARQL
      SELECT ?pid WHERE { ?pid <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/%PID%> }
    SPARQL
    MEMBER_ITQL = <<-ITQL
      select $pid from <#ri> where $pid <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/%PID%>
    ITQL
  end
end
end
end