require 'rubygems'
begin
  require 'bundler'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
require 'rspec'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'cul_scv_hydra'
require 'rake'

Bundler::GemHelper.install_tasks
load "lib/tasks/cmodel.rake" if defined?(Rake)
# require 'spec/rake/spectask'
RSpec::Core::RakeTask.new(:spec) do |spec|
  #spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
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
