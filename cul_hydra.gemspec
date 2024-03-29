# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'cul_hydra/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.2'
  s.name = "cul_hydra"
  s.version = Cul::Hydra::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Benjamin Armintor", "Eric O'Hanlon"]
  s.homepage = "https://github.com/cul/cul_hydra"
  s.email = %q{armintor@gmail.com}
  s.description = "Hydra implementations for CUL repository apps"
  s.summary = "ActiveFedora, OM, and Solrizer implementations for CUL repository apps"

  s.add_dependency("rails", '>= 5.2.3', '< 6.1')
  s.add_dependency("blacklight", "~>7.0")
  s.add_dependency('httpclient')
  # AF 8.7.0 removes ActiveFedora::RDF::Indexing
  s.add_dependency('active-fedora', '>= 8.0', '< 8.7.0')
  s.add_dependency('active-triples', '~> 0.4.0')
  s.add_dependency('active_fedora_finders', '>=0.5.0')
  s.add_dependency('mods')
  s.add_dependency('thread')
  s.add_dependency('rdf', '>=1.1.5')
  s.add_dependency('sparql') # 1.1.5 breaks Ruby 1.9.3 compatibility
  s.add_dependency('json', '>=1.8.3')
  s.add_dependency('rake', '<= 11.3') # Rake >= 11.3 breaks tests
  s.add_dependency('rubydora', '~> 2.1.0')
  s.add_development_dependency "sqlite3", "~> 1.4.2"
  s.add_development_dependency 'rspec-rails', '~> 3.5.0'
  s.add_development_dependency 'rspec-json_expectations'
  s.add_development_dependency "jettywrapper", ">=1.4.0"
  s.add_development_dependency "equivalent-xml", ">= 0.2.4"

  s.files = Dir.glob("{bin,lib,app,config,fixtures}/**/*")
  s.require_paths = ['app','config','lib', 'fixtures']
end
