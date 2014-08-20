namespace :cul_scv_hydra do

  namespace :index do

    task :recursive => :environment do

      puts '---------------------------'
      puts 'Fedora URL: ' + ActiveFedora.config.credentials[:url]
      puts 'Solr URL: ' + ActiveFedora.solr_config[:url]
      puts '---------------------------'

      START_TIME = Time.now

      ENV["RAILS_ENV"] ||= Rails.env
      pid = ENV['pid']
      if ENV['omit']
        pids_to_omit = ENV['omit'].split(',').map{|pid|pid.strip}
      else
        pids_to_omit = nil
      end

      skip_generic_resources = true if ENV['skip_generic_resources'] == 'true'

      begin
        Cul::Scv::Hydra::Indexer.recursively_index_fedora_objects(pid, pids_to_omit, skip_generic_resources, true)
      rescue => e
        puts 'Error: ' + e.message
        puts e.backtrace
        next
      end

    end

  end

end
