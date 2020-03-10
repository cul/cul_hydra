$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'app','models'))
require 'rake/clean'
require 'rubygems'
require 'bundler'
require 'bundler/setup'

begin
# This code is in a begin/rescue block so that the Rakefile is usable
# in an environment where RSpec is unavailable (i.e. production).

require 'jettywrapper'
JETTY_ZIP_BASENAME = 'fedora-3.8.1-with-risearch'
Jettywrapper.url = "https://github.com/cul/hydra-jetty/archive/#{JETTY_ZIP_BASENAME}.zip"

require 'rspec/core/rake_task'

  namespace :cul_hydra do
    RSpec::Core::RakeTask.new(:rspec) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rspec_opts = ['--backtrace'] if ENV['CI']
    end

    RSpec::Core::RakeTask.new(:rcov) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rcov = true
    end
  end
rescue LoadError => e
puts "[Warning] Exception creating rspec rake tasks or loading jettywrapper.  This message can be ignored in environments that intentionally do not pull in the RSpec gem (i.e. production)."
puts e
end

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
  version = Cul::Hydra::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "cul-hydra #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
