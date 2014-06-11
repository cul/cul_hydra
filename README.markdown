# CUL OM and Solrizer Implementations
## To Run Integration Tests
```
bundle exec rake jetty:unzip
bundle exec rake cul_hydra:ci
```
## To Run Unit Tests
```
bundle exec rspec spec/unit
```
## Additions to Solr
###Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer
This Solrizer is basically a clone of the default implementation with a couple of bugfixes and two added features:
#### 1. Collecting terms
Specifying a value for :variant_of[:field_base] in your term definition will cause the term's solr field value to be duplicated in another field whose name will be a combination of the :field_base value and the suffix appropriate to the term's :index_as values
#### 2. Mapping term values
Specifying a value for :variant_of[:map] in your term definition will cause the term value to be used as a lookup key in as specified by the ValueMapper interface (The default is a YAML map in conf/solr_value_maps.yml)

## To-Do
1. A way to funnel term values into a solr field called "text"
