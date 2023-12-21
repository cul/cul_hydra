# frozen_string_literal: true

namespace :cul_hydra do
  namespace :docker do
    task setup_config_files: :environment do
      docker_compose_template_dir = File.join(APP_ROOT, 'docker/templates')
      docker_compose_dest_dir = File.join(APP_ROOT, 'docker')
      Dir.foreach(docker_compose_template_dir) do |entry|
        next unless entry.end_with?('.yml')
        src_path = File.join(docker_compose_template_dir, entry)
        dst_path = File.join(docker_compose_dest_dir, entry.gsub('.template', ''))
        if File.exist?(dst_path)
          puts Rainbow("File already exists (skipping): #{dst_path}").blue.bright + "\n"
        else
          FileUtils.cp(src_path, dst_path)
          puts Rainbow("Created file at: #{dst_path}").green
        end
      end
      spec_config_dir = File.join(APP_ROOT, 'spec/dummy/config')
      config_dir = File.join(APP_ROOT, 'config')
      ['fedora.yml', 'solr.yml'].each do |active_fedora_config|
        src_path = File.join(spec_config_dir, active_fedora_config)
        dst_path = File.join(config_dir, active_fedora_config)
        if File.exist?(dst_path)
          puts Rainbow("File already exists (skipping): #{dst_path}").blue.bright + "\n"
        else
          FileUtils.cp(src_path, dst_path)
          puts Rainbow("Created file at: #{dst_path}").green
        end
      end
    end

    task start: :environment do
      puts "Starting...\n"
      if running?
        puts "\nAlready running."
      else
        # NOTE: This command rebuilds the container images before each run, to ensure they're
        # always up to date. In most cases, the overhead is minimal if the Dockerfile for an image
        # hasn't changed since the last build.
        `docker compose -f #{docker_compose_file_path} up --build --detach --wait`
        wait_for_solr_cores_to_load
        wait_for_fedora_to_load
        puts "\nStarted."
      end
    end

    task stop: :environment do
      puts "Stopping...\n"
      if running?
        puts "\n"
        `docker compose -f #{File.join(APP_ROOT, docker_compose_file_path)} down`
        puts "\nStopped"
      else
        puts "Already stopped."
      end
    end

    task restart: :environment do
      Rake::Task['cul_hydra:docker:stop'].invoke
      Rake::Task['cul_hydra:docker:start'].invoke
    end

    task status: :environment do
      puts running? ? 'Running.' : 'Not running.'
    end

    task delete_volumes: :environment do
      if running?
        puts 'Error: The volumes are currently in use. Please stop the docker services before deleting the volumes.'
        next
      end

      puts Rainbow("This will delete ALL Solr, Redis, and Fedora data for the selected Rails "\
        "environment (#{ENV['environment']}) and cannot be undone. Please confirm that you want to continue "\
        "by typing the name of the selected Rails environment (#{ENV['environment']}):").red.bright
      print '> '
      response = ENV['rails_env_confirmation'] || $stdin.gets.chomp

      puts ""

      if response != ENV['environment']
        puts "Aborting because \"#{ENV['environment']}\" was not entered."
        next
      end

      config = docker_compose_config
      volume_prefix = config['name']
      full_volume_names = config['volumes'].keys.map { |short_name| "#{volume_prefix}_#{short_name}" }

      full_volume_names.map do |full_volume_name|
        if JSON.parse(Open3.capture3("docker volume inspect '#{full_volume_name}'")[0]).length.positive?
          `docker volume rm '#{full_volume_name}'`
          puts Rainbow("Deleted: #{full_volume_name}").green
        else
          puts Rainbow("Skipped: #{full_volume_name} (already deleted)").blue.bright
        end
      end

      puts 'Done.'
    end
  end
end
