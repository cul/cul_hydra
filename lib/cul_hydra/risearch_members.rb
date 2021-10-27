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

    log_risearch_query(recursive_member_query, verbose_output)

    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(recursive_member_query, {
      :type => 'tuples',
      :format => 'json',
      :limit => '',
      :stream => 'on'
    }))

    unique_pids = search_response['results'].map{|result| result['child'].gsub('info:fedora/', '') }.uniq

    return unique_pids

  end

  def get_direct_member_results(pid, flush_resource_index_before_query=false, verbose_output=false, format='json')

    direct_member_query =
      'select $pid from <#ri>
      where $pid <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '>'

    log_risearch_query(direct_member_query, verbose_output)

    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(direct_member_query, {
      :type => 'tuples',
      :format => format,
      :limit => '',
      :stream => 'on',
      :flush => flush_resource_index_before_query.to_s
    }))

    return search_response['results']
  end

  def get_direct_member_pids(pid, flush_resource_index_before_query=false, verbose_output=false)
    unique_pids = get_direct_member_results(pid,flush_resource_index_before_query,verbose_output,'json')
    unique_pids.map{|result| result['pid'].gsub('info:fedora/', '') }.uniq
  end

  def get_direct_member_count(pid, flush_resource_index_before_query=false, verbose_output=false)
    count = get_direct_member_results(pid,flush_resource_index_before_query,verbose_output,'count/json')
    return count.blank? ? 0 : count[0]['count'].to_i
  end

  def get_direct_members_with_datastream_results(pid, dsid, flush_resource_index_before_query=false, verbose_output=false, format='json')
    # Note: The query we're using below is a faster version of this query:
    #   "select $pid from <#ri>
    #   where $pid <http://purl.oclc.org/NET/CUL/memberOf> <fedora:#{pid}>
    #   and $pid <fedora-view:disseminates> $ds
    #   and $ds <fedora-view:disseminationType> <info:fedora/*/#{dsid}>"

    direct_members_with_ds_query = "select $pid
      count( select $ds from <#ri> where  $pid <fedora-view:disseminates> $ds and $ds <fedora-view:disseminationType> <info:fedora/*/#{dsid}>)
      from <#ri>
      where $pid <http://purl.oclc.org/NET/CUL/memberOf> <info:fedora/#{pid}>
      having $k0 <http://mulgara.org/mulgara#occursMoreThan> '0.0'^^<http://www.w3.org/2001/XMLSchema#double>;"

      log_risearch_query(direct_members_with_ds_query, verbose_output)

      search_response = JSON.parse(Cul::Hydra::Fedora.repository.find_by_itql(direct_members_with_ds_query, {
        :type => 'tuples',
        :format => format,
        :limit => '',
        :stream => 'on',
        :flush => flush_resource_index_before_query.to_s
      }))

      return search_response['results']
  end

  def get_direct_members_with_datastream_pids(pid, dsid, flush_resource_index_before_query=false, verbose_output=false)
    unique_pids = get_direct_members_with_datastream_results(pid, dsid, flush_resource_index_before_query, verbose_output, 'json')
    unique_pids.map{|result| result['pid'].gsub('info:fedora/', '') }.uniq
  end

  #Project constituents

  def get_project_constituent_results(pid, verbose_output=false, format='json')

    project_constituent_query =
      'select $pid from <#ri>
      where $pid <info:fedora/fedora-system:def/relations-external#isConstituentOf> <fedora:' + pid + '>'

    log_risearch_query(project_constituent_query, verbose_output)

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

    log_risearch_query(project_constituent_query, verbose_output)

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
  def get_pid_for_identifier(identifier, flush_resource_index_before_query=false)
    find_by_identifier_query = "select $pid from <#ri>
    where $pid <http://purl.org/dc/elements/1.1/identifier> $identifier
    and $identifier <mulgara:is> '#{identifier}'"

    search_response = JSON(Cul::Hydra::Fedora.repository.find_by_itql(find_by_identifier_query, {
      :type => 'tuples',
      :format => 'json',
      :limit => '1',
      :stream => 'on',
      :flush => flush_resource_index_before_query.to_s
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

    pids_to_return = []

    if search_response['results'].present?
      search_response['results'].each do |result|
        pids_to_return << result['pid'].gsub('info:fedora/', '')
      end
    end

    return pids_to_return
  end

  def log_risearch_query(query, verbose_output = false)
    puts "Performing query:\n#{query}" if verbose_output
  end
end
extend ClassMethods
end
