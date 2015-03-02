module Cul::Scv::Hydra::RisearchMembers
  extend ActiveSupport::Concern
  included do
    include Cul::Hydra::RisearchMembers
  end

  #Project constituents

  def self.get_project_constituent_results(pid, verbose_output=false, format='json')

    project_constituent_query =
      'select $pid from <#ri>
      where $pid <info:fedora/fedora-system:def/relations-external#isConstituentOf> <fedora:' + pid + '>'

    puts 'Performing query:' if verbose_output
    puts project_constituent_query if verbose_output

    search_response = JSON(Cul::Scv::Fedora.repository.find_by_itql(project_constituent_query, {
      :type => 'tuples',
      :format => format,
      :limit => '',
      :stream => 'on'
    }))

    return search_response['results']
  end

  def self.get_project_constituent_pids(pid, verbose_output=false)
    unique_pids = get_project_constituent_results(pid,verbose_output,'json')
    unique_pids.map{|result| result['pid'].gsub('info:fedora/', '') }.uniq
  end

  def self.get_project_constituent_count(pid, verbose_output=false)
    count = get_project_constituent_results(pid,verbose_output,'count/json')
    return count.blank? ? 0 : count[0]['count'].to_i
  end

end
