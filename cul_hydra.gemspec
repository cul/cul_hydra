# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'cul_hydra/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.9.3'
  s.name = "cul_hydra"
  s.version = Cul::Hydra::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Benjamin Armintor", "Eric O'Hanlon"]
  s.homepage = "https://github.com/cul/cul_hydra"
  s.email = %q{armintor@gmail.com}
  s.description = "Hydra implementations for CUL repository apps"
  s.summary = "ActiveFedora, OM, and Solrizer implementations for CUL repository apps"

  s.add_dependency("blacklight")
  s.add_dependency('hydra-head', "~>7")
  s.add_dependency('httpclient')
  s.add_dependency('active-fedora', '~> 7.0')
  s.add_dependency('active-triples', '~> 0.2.2')
  s.add_dependency('active_fedora_finders', '>=0.5.0')
  s.add_dependency('active_fedora_relsint', '~>0.4')
  s.add_dependency('cul_image_props')
  s.add_dependency('mods')
  s.add_dependency('thread')
  s.add_dependency('rdf', '>=1.1.5')
  s.add_dependency('sparql', '1.1.4') # 1.1.5 breaks Ruby 1.9.3 compatibility
  
  # Two dependencies below are locked to allow continued support for Ruby 1.9
  s.add_dependency('cancancan', '~>1.12.0')
  s.add_dependency('autoprefixer-rails', '<= 6.1.1')

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec", "~>2.10"
  s.add_development_dependency "rspec-rails", "~>2.10"
  s.add_development_dependency "jettywrapper", ">=1.4.0"
  s.add_development_dependency "equivalent-xml", ">= 0.2.4"
  s.add_development_dependency "rbx-require-relative"

  s.files = Dir.glob("{bin,lib,app,config,fixtures}/**/*")
  s.require_paths = ['app','config','lib', 'fixtures']
end
