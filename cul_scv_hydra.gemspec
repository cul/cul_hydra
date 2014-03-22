# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'cul_scv_hydra/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.9.3'
  s.name = "cul_scv_hydra"
  s.version = Cul::Scv::Hydra::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Benjamin Armintor"]
  s.homepage = "https://github.com/cul/cul_scv_hydra"
  s.email = %q{armintor@gmail.com}
  s.description = "ActiveFedora, OM, and Solrizer implementations for CUL Staff Collection Viewer"
  s.summary = "ActiveFedora, OM, and Solrizer implementations for CUL Staff Collection Viewer"

  s.add_dependency("blacklight", ">= 4.0.0")
  s.add_dependency('active-fedora', ">= 6.7.0")
  s.add_dependency('hydra-head', "6.4.1")
  s.add_dependency('active_fedora_finders')
  s.add_dependency('active_fedora_relsint')
  s.add_dependency('cul_image_props')
  #s.add_dependency('mediashelf-loggable', ">=0.4.7")
  #s.add_dependency('nokogiri', ">= 1.4.2")
  s.add_dependency('mods')
  s.add_dependency('om')
  s.add_dependency('solrizer', "~>3.0")
  s.add_development_dependency "rspec", "~>2.10"
  s.add_development_dependency "rspec-rails", "~>2.10"
  s.add_development_dependency "mocha", "0.12.7"
  s.add_development_dependency "equivalent-xml", ">= 0.2.4"
  s.add_development_dependency "rbx-require-relative"

  s.files = Dir.glob("{bin,lib,app,config}/**/*")
  s.require_paths = ['lib', 'fixtures']
end
