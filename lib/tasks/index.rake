require 'thread/pool'

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
      
      if ENV['THREADS'].present?
        thread_pool_size = ENV['THREADS'].to_i
        puts "Number of threads: #{thread_pool_size}"
      else
        thread_pool_size = 1
        puts "Number of threads: #{thread_pool_size}"
      end

      skip_generic_resources = (ENV['skip_generic_resources'] == 'true')
      
      ### Stop excessive ActiveFedora logging ###
      # initialize the fedora connection if necessary
      connection = (ActiveFedora::Base.fedora_connection[0] ||= ActiveFedora::RubydoraConnection.new(ActiveFedora.config.credentials)).connection
      # the logger accessor is private
      (connection.api.send :logger).level = Logger::INFO

      start_time = Time.now
      pids = Cul::Hydra::RisearchMembers.get_project_constituent_pids(project_pid, true)
      total = pids.length
      puts "Found #{total} project members."
      counter = 0
      
      # We run into autoloading issues when running in a multithreaded context,
      # so we'll have the application eager load all classes now.
      Rails.application.eager_load!
      # Hack: Force load of classes that are giving autoload errors by referencing them below
      BagAggregator.to_s
      ContentAggregator.to_s
      GenericResource.to_s
      
      ###########################################
      pool = Thread.pool(thread_pool_size)
      mutex = Mutex.new

      pids.each do |pid|
        pool.process {
          
          Cul::Hydra::Indexer.index_pid(pid, skip_generic_resources, false)
          
          mutex.synchronize do
            counter += 1
            puts "Indexed #{counter} of #{total} | #{Time.now - start_time} seconds"
          end
        }
      end

      pool.shutdown
      ###########################################
      
      puts 'Done'

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