module Cul::Hydra::Indexer

  NUM_FEDORA_RETRY_ATTEMPTS = 3
  DELAY_BETWEEN_FEDORA_RETRY_ATTEMPTS = 5.seconds
  DEFAULT_INDEX_OPTS = {
    skip_resources: false, verbose_output: false, softcommit: true, reraise: false
  }.freeze
  def self.descend_from(pid, pids_to_omit=nil, verbose_output=false)
    if pid.blank?
      raise 'Please supply a pid (e.g. rake recursively_index_fedora_objects pid=ldpd:123)'
    end

    begin

      unless ActiveFedora::Base.exists?(pid)
        raise 'Could not find Fedora object with pid: ' + pid
      end

      if pids_to_omit.present? && pids_to_omit.include?(pid)
        puts 'Skipping topmost object in this set (' + pid + ') because it has been intentionally omitted...' if verbose_output
      else
        puts 'Indexing topmost object in this set (' + pid + ')...' if verbose_output
        puts 'If this is a BagAggregator with a lot of members, this may take a while...' if verbose_output

        yield pid

      end

      puts 'Recursively retreieving and indexing all members of ' + pid + '...'

      unique_pids = Cul::Hydra::RisearchMembers.get_recursive_member_pids(pid, true)

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

          puts 'Recursing on ' + i.to_s + ' of ' + total_number_of_members.to_s + ' members (' + pid + ')...' if verbose_output

          yield pid

          i += 1
        }
      end

    rescue RestClient::Unauthorized => e
      error_message = "Skipping #{pid} due to error: " + e.message + '.  Problem with Fedora object?'
      puts error_message
      logger.error error_message if defined?(logger)
    end

    puts 'Recursion complete!'

  end
  def self.recursively_index_fedora_objects(top_pid, pids_to_omit=nil, skip_generic_resources=false, verbose_output=false)

    index_opts = { skip_generic_resources: skip_generic_resources, verbose_output: verbose_output }
    descend_from(top_pid, pids_to_omit, verbose_output) do |pid|
      self.index_pid(pid, index_opts)
    end
  end

  # legacy positional opts signature: skip_resources = false, verbose_output = false, softcommit = true
  # 
  def self.extract_index_opts(args)
    args = args.dup # do not modify the original list
    # extract opts hash
    index_opts = (args.last.is_a? Hash) ? args.pop : {}
    # symbolize keys and reverse merge defaults
    index_opts = index_opts.map {|k,v| [k.to_sym, v] }.to_h
    index_opts = DEFAULT_INDEX_OPTS.merge(index_opts)
    # assign any legacy positional arguments, permitting explicit nils
    unless args.empty?
      index_opts[:skip_resources] = args[0] if args.length > 0
      index_opts[:verbose_output] = args[1] if args.length > 1
      index_opts[:softcommit] = args[2] if args.length > 2
    end
    index_opts
  end

  def self.index_pid(pid, *args)
    # We found an object with the desired PID. Let's reindex it
    index_opts = extract_index_opts(args)
    begin
      active_fedora_object = nil

      NUM_FEDORA_RETRY_ATTEMPTS.times do |i|
        begin
          active_fedora_object = ActiveFedora::Base.find(pid, :cast => true)
          if skip_generic_resources && active_fedora_object.is_a?(GenericResource)
            puts 'Object was skipped because GenericResources are being skipped and it is a GenericResource.'
          else
            if index_opts[:softcommit]
              active_fedora_object.update_index
            else
              # Using direct solr query to update document without soft commiting
              ActiveFedora::SolrService.add(active_fedora_object.to_solr)
            end
            puts 'done.' if index_opts[:verbose_output]
          end
          break
        rescue RestClient::RequestTimeout, Errno::EHOSTUNREACH => e
          remaining_attempts = (NUM_FEDORA_RETRY_ATTEMPTS-1) - i
          if remaining_attempts == 0
            raise
          else
            Rails.logger.error "Error: Could not connect to fedora. (#{e.class.to_s + ': ' + e.message}).  Will retry #{remaining_attempts} more #{remaining_attempts == 1 ? 'time' : 'times'} (after a #{DELAY_BETWEEN_FEDORA_RETRY_ATTEMPTS} second delay)."
            sleep DELAY_BETWEEN_FEDORA_RETRY_ATTEMPTS
          end
        rescue RuntimeError => e
          if e.message.index('Circular dependency detected while autoloading')
            # The RuntimeError 'Circular dependency detected while autoloading CLASSNAME' comes up when
            # we're doing multithreaded indexing. Waiting a few seconds for the class to autoload and then
            # retrying seems to help with this.
            sleep 5
          else
            # Other RuntimeErrors should be passed on
            raise
          end
        end
      end
    rescue SystemExit, Interrupt => e
      # Allow system interrupt (ctrl+c)
      raise
    rescue Exception => e
      puts "Encountered problem with #{pid}.  Skipping record.  Exception class: #{e.class.name}.  Message: #{e.message}"
      if index_opts[:reraise]
        raise
      end
    end
  end
end
