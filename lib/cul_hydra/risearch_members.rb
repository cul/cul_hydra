# TODO: Eventually change this class name from RisearchMembers to RisearchHelpers
module Cul::Hydra::RisearchMembers
module ClassMethods
  def get_recursive_member_pids(pid, verbose_output=false, cmodel_type='all')

    recursive_member_query =
      'select $child $parent from <#ri>
      where
      walk($child <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '> and $child <http://purl.oclc.org/NET/CUL/memberOf> $parent)'      

    unless cmodel_type == 'all'
      recursive_member_query += ' and $child <fedora-model:hasModel> $cmodel'
      recursive_member_query += ' and $cmodel <mulgara:is> <info:fedora/ldpd:' + cmodel_type + '>'
    end

    puts 'Performing query:' if verbose_output
    puts recursive_member_query if verbose_output

    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(recursive_member_query, {
      :type => 'tuples',
      :format => 'json',
      :limit => '',
      :stream => 'on'
    }))

    unique_pids = search_response['results'].map{|result| result['child'].gsub('info:fedora/', '') }.uniq

    return unique_pids

  end

  def get_direct_member_results(pid, verbose_output=false, format='json')

    direct_member_query =
      'select $pid from <#ri>
      where $pid <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '>'

    puts 'Performing query:' if verbose_output
    puts direct_member_query if verbose_output

    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(direct_member_query, {
      :type => 'tuples',
      :format => format,
      :limit => '',
      :stream => 'on'
    }))

    return search_response['results']
  end

  def get_direct_member_pids(pid, verbose_output=false)
    unique_pids = get_direct_member_results(pid,verbose_output,'json')
    unique_pids.map{|result| result['pid'].gsub('info:fedora/', '') }.uniq
  end

  def get_direct_member_count(pid, verbose_output=false)
    count = get_direct_member_results(pid,verbose_output,'count/json')
    return count.blank? ? 0 : count[0]['count'].to_i
  end

  #Project constituents

  def get_project_constituent_results(pid, verbose_output=false, format='json')

    project_constituent_query =
      'select $pid from <#ri>
      where $pid <info:fedora/fedora-system:def/relations-external#isConstituentOf> <fedora:' + pid + '>'

    puts 'Performing query:' if verbose_output
    puts project_constituent_query if verbose_output

    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(project_constituent_query, {
      :type => 'tuples',
      :format => format,
      :limit => '',
      :stream => 'on'
    }))

    return search_response['results']
  end

  def get_project_constituent_pids(pid, verbose_output=false)
    unique_pids = get_project_constituent_results(pid,verbose_output,'json')
    unique_pids.map{|result| result['pid'].gsub('info:fedora/', '') }.uniq
  end

  def get_project_constituent_count(pid, verbose_output=false)
    count = get_project_constituent_results(pid,verbose_output,'count/json')
    return count.blank? ? 0 : count[0]['count'].to_i
  end
  
  #Publish target members
  
  def get_publish_target_member_results(pid, verbose_output=false, format='json')

    project_constituent_query =
      'select $pid from <#ri>
      where $pid <http://purl.org/dc/terms/publisher> <fedora:' + pid + '>'

    puts 'Performing query:' if verbose_output
    puts project_constituent_query if verbose_output

    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(project_constituent_query, {
      :type => 'tuples',
      :format => format,
      :limit => '',
      :stream => 'on'
    }))

    return search_response['results']
  end

  def get_publish_target_member_pids(pid, verbose_output=false)
    unique_pids = get_publish_target_member_results(pid,verbose_output,'json')
    unique_pids.map{|result| result['pid'].gsub('info:fedora/', '') }.uniq
  end

  def get_publish_target_member_count(pid, verbose_output=false)
    count = get_publish_target_member_results(pid,verbose_output,'count/json')
    return count.blank? ? 0 : count[0]['count'].to_i
  end
  
  # Returns the pid of the first object found with the given identifier
  def get_pid_for_identifier(identifier)
    find_by_identifier_query = "select $pid from <#ri>
    where $pid <http://purl.org/dc/elements/1.1/identifier> $identifier
    and $identifier <mulgara:is> '#{identifier}'"
    
    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(find_by_identifier_query, {
      :type => 'tuples',
      :format => 'json',
      :limit => '1',
      :stream => 'on'
    }))
    
    if search_response['results'].present?
      return search_response['results'].first['pid'].gsub('info:fedora/', '')
    else
      return nil
    end
  end
  
  # Returns the pids of ALL objects found with the given identifier
  def get_all_pids_for_identifier(identifier)
    
    find_by_identifier_query = "select $pid from <#ri>
    where $pid <http://purl.org/dc/elements/1.1/identifier> $identifier
    and $identifier <mulgara:is> '#{identifier}'"
    
    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(find_by_identifier_query, {
      :type => 'tuples',
      :format => 'json',
      :limit => '',
      :stream => 'on'
    }))
    
    puts 'searching for: ' + identifier.inspect
    puts 'with query: ' + find_by_identifier_query.inspect
    puts 'search_response: ' + search_response.inspect
    
    pids_to_return = []
    
    if search_response['results'].present?
      search_response['results'].each do |result|
        pids_to_return << result['pid'].gsub('info:fedora/', '')
      end
    end
    
    return pids_to_return
  end
  
end
extend ClassMethods
end