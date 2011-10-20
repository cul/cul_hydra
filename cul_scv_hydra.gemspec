# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'cul_scv_hydra/version'

Gem::Specification.new do |s|
  s.name = "cul_scv_hydra"
  s.version = Cul::Scv::Hydra::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Benjamin Armintor"]
  s.email = %q{armintor@gmail.com}
  s.description = "OM (Opinionated Metadata) and Solrizer libraries for CUL Staff Collection Viewer's MODS and DC profiles"
  s.summary = "OM (Opinionated Metadata) and Solrizer libraries for CUL Staff Collection Viewer's MODS and DC profiles"

  s.add_dependency('active-fedora', ">= 2.3.0")
  s.add_dependency('om', ">= 1.2.4")
  s.add_dependency('nokogiri', ">= 1.4.2")
  s.add_development_dependency "rspec", "<2.0.0"
  s.add_development_dependency "mocha", ">= 0.9.8"
  s.add_development_dependency "ruby-debug"
  s.add_development_dependency "equivalent-xml", ">= 0.2.4"

  s.files = Dir.glob("{bin,lib}/**/*")
  s.require_path = 'lib'
end
