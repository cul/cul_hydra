APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../") unless defined?(APP_ROOT)

require 'jettywrapper'
JETTY_ZIP_BASENAME = '7.x-stable'
Jettywrapper.url = "https://github.com/projecthydra/hydra-jetty/archive/#{JETTY_ZIP_BASENAME}.zip"

namespace :cul_hydra do

  begin
    # This code is in a begin/rescue block so that the Rakefile is usable
    # in an environment where RSpec is unavailable (i.e. production).

    require 'rspec/core/rake_task'

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

  rescue LoadError => e
    puts "[Warning] Exception creating rspec rake tasks.  This message can be ignored in environments that intentionally do not pull in the RSpec gem (i.e. production)."
    puts e
  end

  desc "CI build"
  task :ci do
    ENV['environment'] = "test"
    #Rake::Task["active_fedora:configure_jetty"].invoke
    jetty_params = Jettywrapper.load_config
    error = Jettywrapper.wrap(jetty_params) do
      Rake::Task["cul_hydra:cmodel:reload_all"].invoke
      Rake::Task['cul_hydra:coverage'].invoke
    end
    raise "test failures: #{error}" if error
  end

  desc "Execute specs with coverage"
  task :coverage do
    # Put spec opts in a file named .rspec in root
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'

   # Rake::Task["active_fedora:fixtures"].invoke
    Rake::Task["cul_hydra:rspec"].invoke
  end

end