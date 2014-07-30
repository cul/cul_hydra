module Cul::Scv::Hydra::Indexer

  def self.recursively_index_fedora_objects(pid, pids_to_omit=nil, skip_generic_resources=false, verbose_output=false)

    if pid.blank?
      raise 'Please supply a pid (e.g. rake recursively_index_fedora_objects pid=ldpd:123)'
    end

    unless ActiveFedora::Base.exists?(pid)
      raise 'Could not find Fedora object with pid: ' + pid
    end

    if pids_to_omit.present? && pids_to_omit.include?(pid)
      puts 'Skipping indexing of topmost object in this set (' + pid + ') because it has been intentionally omitted...' if verbose_output
    else
      puts 'Indexing topmost object in this set (' + pid + ')...' if verbose_output
      puts 'If this is a BagAggregator with a lot of members, this may take a while...' if verbose_output

      # We found an object with the desired PID. Let's reindex it
      active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)

      if skip_generic_resources && active_fedora_object.is_a?(GenericResource)
        puts 'Top level object was skipped because GenericResources are being skipped and it is a GenericResource.'
      else
        begin
          active_fedora_object.update_index
        rescue Exception => e
          puts 'Encountered problem.  Skipping record.  Exception: ' + e.message
        end
        puts 'Done indexing topmost object (' + pid + '). Took ' + (Time.now - START_TIME).to_s + ' seconds' if verbose_output
      end

    end

    puts 'Recursively retreieving and indexing all members of ' + pid + '...'

    unique_pids = Cul::Scv::Hydra::RisearchMembers.get_recursive_member_pids(pid, true)

    total_number_of_members = unique_pids.length
    puts 'Recursive search found ' + total_number_of_members.to_s + ' members.' if verbose_output

    if pids_to_omit.present?
      unique_pids = unique_pids - pids_to_omit
      total_number_of_members = unique_pids.length
      puts 'After checking against the list of omitted pids, the total number of objects to index will be: ' + total_number_of_members.to_s if verbose_output
    end

    i = 1
    if total_number_of_members > 0
      unique_pids.each {|pid|

        print 'Indexing ' + i.to_s + ' of ' + total_number_of_members.to_s + ' members (' + pid + ')...' if verbose_output

        active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)

        if skip_generic_resources && active_fedora_object.is_a?(GenericResource)
          puts "skipped (because we're skipping GenericResources." if verbose_output
        else
          begin
            active_fedora_object.update_index
          rescue Exception => e
            puts 'Encountered problem.  Skipping record.  Exception: ' + e.message
          end
          # Display progress
          puts 'done.' if verbose_output
        end

        i += 1
      }
    end

    puts 'Indexing complete!  Took ' + (Time.now - START_TIME).to_s + ' seconds'

  end

end
