# -*- encoding : utf-8 -*-
# lib/cul_scv_hydra/engine.rb
require "cul_scv_hydra"
require "rails"

module Cul::Scv::Hydra
  class Engine < ::Rails::Engine
  	isolate_namespace Cul::Scv::Hydra

    config.mount_at = '/'

    config.autoload_paths += %W(
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
    )

    config.generators do |g|
      g.test_framework :rspec
      g.integration_tool :rspec
    end

    # Make the rake tasks visible.
    rake_tasks do
      Dir.chdir(File.expand_path(File.join(File.dirname(__FILE__), '..'))) do
        Dir.glob(File.join('tasks', '*.rake')).each do |railtie|
          #load railtie # Commenting this out for now because we appear to be loading rake tasks twice
        end
      end
    end
  end
end
