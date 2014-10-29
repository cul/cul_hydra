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

  end

end
