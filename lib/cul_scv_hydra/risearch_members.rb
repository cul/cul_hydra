module Cul::Scv::Hydra::RisearchMembers

  def self.get_recursive_member_pids(pid, verbose_output=false, cmodel_type='all')

    recursive_member_query =
      'select $child $parent $cmodel from <#ri>
      where
      walk($child <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '> and $child <http://purl.oclc.org/NET/CUL/memberOf> $parent)
      and
      $child <fedora-model:hasModel> $cmodel'

    unless cmodel_type == 'all'
      recursive_member_query += ' and $cmodel <mulgara:is> <info:fedora/ldpd:' + cmodel_type + '>'
    end

    puts 'Performing query:' if verbose_output
    puts recursive_member_query if verbose_output

    search_response = JSON(Cul::Scv::Fedora.repository.find_by_itql(recursive_member_query, {
      :type => 'tuples',
      :format => 'json',
      :limit => '',
      :stream => 'on'
    }))

    unique_pids = search_response['results'].map{|result| result['child'].gsub('info:fedora/', '') }.uniq

    return unique_pids

  end

  def self.get_direct_member_pids(pid, verbose_output=false)

    direct_member_query =
      'select $pid $cmodel from <#ri>
      where $pid <http://purl.oclc.org/NET/CUL/memberOf> <fedora:' + pid + '>
      and $pid <fedora-model:hasModel> $cmodel'

    puts 'Performing query:' if verbose_output
    puts direct_member_query if verbose_output

    search_response = JSON(Cul::Scv::Fedora.repository.find_by_itql(direct_member_query, {
      :type => 'tuples',
      :format => 'json',
      :limit => '',
      :stream => 'on'
    }))

    unique_pids = search_response['results'].map{|result| result['pid'].gsub('info:fedora/', '') }.uniq

    return unique_pids

  end

end
