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
      if pid.blank?
        puts 'Please supply a pid (e.g. rake recursively_index_fedora_objects pid=ldpd:123)'
        next
      end

      unless ActiveFedora::Base.exists?(pid)
        puts 'Could not find Fedora object with PID: ' + pid
        next
      end

      if ENV['skip_top_level_object_indexing']
        puts 'Skipping top level object indexing (' + pid + ')'
      else
        puts 'Indexing topmost object in this set (' + pid + ')...'
        puts 'If this is a BagAggregator with a lot of members, this will take a while...'

        # We found an object with the desired PID. Let's reindex it
        active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)
        active_fedora_object.update_index

        puts 'Done indexing topmost object (' + pid + '). Took ' + (Time.now - START_TIME).to_s + ' seconds'
      end

      puts 'Recursively retreieving and indexing all members...'

      member_query =
        'select $child $parent $cmodel from <#ri>
        where
        walk($child <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '> and $child <http://purl.oclc.org/NET/CUL/memberOf> $parent)
        and
        $child <fedora-model:hasModel> $cmodel'

      puts 'Performing query:'
      puts member_query

      search_response = JSON(Cul::Scv::Fedora.repository.find_by_itql(member_query, {
        :type => 'tuples',
        :format => 'json',
        :limit => '',
        :stream => 'on'
      }))

      unique_pids = search_response['results'].map{|result| result['child'].gsub('info:fedora/', '') }.uniq

      total_number_of_members = unique_pids.length
      puts 'Recursive search found ' + total_number_of_members.to_s + ' members.'

      i = 1
      if total_number_of_members > 0
        unique_pids.each {|pid|

          print 'Indexing ' + i.to_s + ' of ' + total_number_of_members.to_s + ' members (' + pid + ')...'

          active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)
          active_fedora_object.update_index

          # Display progress
          puts 'done.'

          i += 1
        }
      end

      puts 'Indexing complete!  Took ' + (Time.now - START_TIME).to_s + ' seconds'

    end

  end

end
