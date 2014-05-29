namespace :cul_scv_hydra do

  namespace :index do

    task :recursively_index_fedora_objects => :environment do

      puts '---------------------------'
      puts 'Fedora URL: ' + ActiveFedora.config.credentials[:url]
      puts 'Solr URL: ' + ActiveFedora.solr_config[:url]
      puts '---------------------------'

      START_TIME = Time.now

      #lindquist == burke_lindq == ldpd:130509

      ENV["RAILS_ENV"] ||= Rails.env
      pid = ENV['pid']
      skip_top_level_object_indexing = ( ! ENV['skip_top_level_object_indexing'].blank? && ENV['skip_top_level_object_indexing'])

      begin
        Cul::Scv::Hydra::Indexer.recursively_index_fedora_objects(pid, skip_top_level_object_indexing, true)
      rescue => e
        puts 'Error: ' + e.message
        puts e.backtrace
        next
      end

    end

  end

end
