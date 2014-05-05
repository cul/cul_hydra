$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app','models'))
require 'rubygems'
begin
  require 'bundler'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
require 'rspec'
require 'rspec/core/rake_task'

Bundler::GemHelper.install_tasks
if defined?(Rake)
  Dir.glob("lib/tasks/*.rake").each do |rakefile|
    import rakefile
  end
end
# require 'spec/rake/spectask'

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = Cul::Scv::Hydra::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cul-om-scv #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
