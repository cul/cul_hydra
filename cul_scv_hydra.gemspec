# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'cul_scv_hydra/version'

Gem::Specification.new do |s|
  s.name = "cul_scv_hydra"
  s.version = Cul::Scv::Hydra::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Benjamin Armintor"]
  s.homepage = "https://github.com/cul/cul_scv_hydra"
  s.email = %q{armintor@gmail.com}
  s.description = "ActiveFedora, OM, and Solrizer implementations for CUL Staff Collection Viewer"
  s.summary = "ActiveFedora, OM, and Solrizer implementations for CUL Staff Collection Viewer"

  s.add_dependency('cul_image_props')
  s.add_dependency("blacklight", "~> 3.1.2")
  s.add_dependency('rails', "~> 3.0.10")
  s.add_dependency('activemodel', "~> 3.0.10")
  s.add_dependency('activeresource', "~> 3.0.10")
  s.add_dependency('activesupport', "~> 3.0.10")
  s.add_dependency('active-fedora', "~> 3.3.0")
  s.add_dependency('mediashelf-loggable', ">=0.4.7")
  s.add_dependency('rubydora', '>=0.2.6')
  s.add_dependency('hydra-head', "~> 3.3.0")
  s.add_dependency('nokogiri', ">= 1.4.2")
  s.add_dependency('om', ">= 1.2.4")
  s.add_dependency('solrizer', ">= 1.1.2")
  s.add_development_dependency "rspec", "~>2.8.0"
  s.add_development_dependency "rspec-rails", "~>2.8.1"
  s.add_development_dependency "mocha", ">= 0.9.8"
  s.add_development_dependency "equivalent-xml", ">= 0.2.4"
  s.add_development_dependency "rbx-require-relative", "= 0.0.5"

  s.files = Dir.glob("{bin,lib,app,config}/**/*")
  s.require_path = 'lib'
end
