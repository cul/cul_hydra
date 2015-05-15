namespace :cul_hydra do

  namespace :index do

    task :recursive => :environment do

      puts '---------------------------'
      puts 'Fedora URL: ' + ActiveFedora.config.credentials[:url]
      puts 'Solr URL: ' + ActiveFedora.solr_config[:url]
      puts '---------------------------'

      ENV["RAILS_ENV"] ||= Rails.env

      if ENV['PIDS']
        pids = ENV['PIDS'].split(',')
      else
        puts 'Please specify one or more comma-delimited pids to recurse over (e.g. PIDS=ldpd:123 or PIDS=ldpd:123,ldpd:456)'
        next
      end

      if ENV['OMIT']
        pids_to_omit = ENV['OMIT'].split(',').map{|pid|pid.strip}
      else
        pids_to_omit = nil
      end

      skip_generic_resources = (ENV['skip_generic_resources'] == 'true')

      begin
        pids.each do |pid|
          Cul::Hydra::Indexer.recursively_index_fedora_objects(pid, pids_to_omit, skip_generic_resources, true)
        end
      rescue => e
        puts 'Error: ' + e.message
        puts e.backtrace
        next
      end

    end

    task :by_project_pid => :environment do

      puts '---------------------------'
      puts 'Fedora URL: ' + ActiveFedora.config.credentials[:url]
      puts 'Solr URL: ' + ActiveFedora.solr_config[:url]
      puts '---------------------------'

      if ENV['PID']
        project_pid = ENV['PID']
      else
        puts 'Please specify a project PID (e.g. PID=cul:123)'
        next
      end

      skip_generic_resources = (ENV['skip_generic_resources'] == 'true')

      start_time = Time.now
      pids = Cul::Hydra::RisearchMembers.get_project_constituent_pids(project_pid, true)
      total = pids.length
      puts "Found #{total} project members."
      counter = 0

      pids.each do |pid|
        Cul::Hydra::Indexer.index_pid(pid, skip_generic_resources, false)
        counter += 1
        puts "Indexed #{counter} of #{total} | #{Time.now - start_time} seconds"
      end

    end
    
    task :by_publish_target_pid => :environment do

      puts '---------------------------'
      puts 'Fedora URL: ' + ActiveFedora.config.credentials[:url]
      puts 'Solr URL: ' + ActiveFedora.solr_config[:url]
      puts '---------------------------'

      if ENV['PID']
        publish_target_pid = ENV['PID']
      else
        puts 'Please specify a publish target PID (e.g. PID=cul:123)'
        next
      end

      skip_generic_resources = (ENV['skip_generic_resources'] == 'true')

      start_time = Time.now
      pids = Cul::Hydra::RisearchMembers.get_publish_target_member_pids(publish_target_pid, true)
      total = pids.length
      puts "Found #{total} publish target members."
      counter = 0

      pids.each do |pid|
        Cul::Hydra::Indexer.index_pid(pid, skip_generic_resources, false)
        counter += 1
        puts "Indexed #{counter} of #{total} | #{Time.now - start_time} seconds"
      end

    end

  end

end