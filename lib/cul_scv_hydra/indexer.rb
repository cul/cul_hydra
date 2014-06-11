module Cul::Scv::Hydra::Indexer

  def self.recursively_index_fedora_objects(pid, skip_top_level_object_indexing=false, verbose_output=false)

    if pid.blank?
      raise 'Please supply a pid (e.g. rake recursively_index_fedora_objects pid=ldpd:123)'
    end

    unless ActiveFedora::Base.exists?(pid)
      raise 'Could not find Fedora object with pid: ' + pid
    end

    if skip_top_level_object_indexing
      puts 'Skipping top level object indexing (' + pid + ')' if verbose_output
    else
      puts 'Indexing topmost object in this set (' + pid + ')...' if verbose_output
      puts 'If this is a BagAggregator with a lot of members, this will take a while...' if verbose_output

      # We found an object with the desired PID. Let's reindex it
      active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)
      active_fedora_object.update_index

      puts 'Done indexing topmost object (' + pid + '). Took ' + (Time.now - START_TIME).to_s + ' seconds' if verbose_output
    end

    puts 'Recursively retreieving and indexing all members...'

    unique_pids = Cul::Scv::Hydra::RisearchMembers.get_recursive_member_pids(pid, true)

    total_number_of_members = unique_pids.length
    puts 'Recursive search found ' + total_number_of_members.to_s + ' members.' if verbose_output

    i = 1
    if total_number_of_members > 0
      unique_pids.each {|pid|

        print 'Indexing ' + i.to_s + ' of ' + total_number_of_members.to_s + ' members (' + pid + ')...' if verbose_output

        active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)
        active_fedora_object.update_index

        # Display progress
        puts 'done.' if verbose_output

        i += 1
      }
    end

    puts 'Indexing complete!  Took ' + (Time.now - START_TIME).to_s + ' seconds' if verbose_output

  end

end
