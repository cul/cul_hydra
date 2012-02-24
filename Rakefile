require 'rubygems'
require 'rspec'
require 'rake/testtask'
require 'cul_scv_hydra'
begin
  require 'bundler'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
require 'rake'

# require 'spec/rake/spectask'
RSpec::Rake::SpecTask.new(:spec) do |spec|
  #spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Rake::SpecTask.new(:rcov) do |spec|
  #spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = Cul::Scv::Hydra::VERSION 

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cul-om-scv #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
