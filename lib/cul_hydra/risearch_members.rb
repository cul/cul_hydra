module Cul::Hydra::RisearchMembers

  def self.get_recursive_member_pids(pid, verbose_output=false, cmodel_type='all')

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

  def self.get_direct_member_results(pid, verbose_output=false, format='json')

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

  def self.get_direct_member_pids(pid, verbose_output=false)
    unique_pids = get_direct_member_results(pid,verbose_output,'json')
    unique_pids.map{|result| result['pid'].gsub('info:fedora/', '') }.uniq
  end
  
  def self.get_direct_member_count(pid, verbose_output=false)
    count = get_direct_member_results(pid,verbose_output,'count/json')
    return count.blank? ? 0 : count[0]['count'].to_i
  end
end