namespace :cul_scv_hydra do

  namespace :index do

    task :recursive => :environment do

      puts '---------------------------'
      puts 'Fedora URL: ' + ActiveFedora.config.credentials[:url]
      puts 'Solr URL: ' + ActiveFedora.solr_config[:url]
      puts '---------------------------'

      START_TIME = Time.now

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

      skip_generic_resources = true if ENV['skip_generic_resources'] == 'true'

      begin
        pids.each do |pid|
          Cul::Scv::Hydra::Indexer.recursively_index_fedora_objects(pid, pids_to_omit, skip_generic_resources, true)
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

      START_TIME = Time.now
      pids = Cul::Scv::Hydra::RisearchMembers.get_project_constituent_pids(project_pid, true)

      puts "Found #{pids.length} project members."

      pids.each do |pid|
        Cul::Scv::Hydra::Indexer.index_pid(pid, false, false)
      end

    end

  end

end
