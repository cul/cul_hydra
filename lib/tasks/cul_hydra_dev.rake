APP_ROOT = File.expand_path("#{File.dirname(__FILE__)}/../../") unless defined?(APP_ROOT)

namespace :cul_hydra do
  desc "CI build"
  task :ci do
    ENV['environment'] = "test"
    #Rake::Task["active_fedora:configure_jetty"].invoke
    jetty_params = Jettywrapper.load_config
    Rake::Task["jetty:clean"].invoke
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