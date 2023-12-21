APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../") unless defined?(APP_ROOT)

namespace :cul_hydra do
  desc "CI build"
  task ci: ['cul_hydra:docker:setup_config_files'] do
    ENV['environment'] = "test"
    ENV['RAILS_ENV'] = "test"
    docker_wrapper do
      Rake::Task["cul_hydra:cmodel:reload_all"].invoke
      Rake::Task['cul_hydra:coverage'].invoke
    end
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