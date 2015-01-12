$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app','models'))
require 'rake/clean'
require 'bundler'
Bundler::GemHelper.install_tasks
Dir.glob("lib/tasks/*.rake").each do |rakefile|
  load rakefile
end

CLEAN.include %w[**/.DS_Store tmp *.log *.orig *.tmp **/*~]

task :ci => ['jetty:clean', 'cul_hydra:ci']
task :spec => ['cul_hydra:rspec']
task :rcov => ['cul_hydra:rcov']


task :default => [:ci]

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = Cul::Scv::Hydra::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cul-hydra #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
