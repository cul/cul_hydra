module Cul::Scv::Hydra::AccessControlsEnforcement

  private

  def build_lucene_query(user_query)
    q = ""
    # start query of with user supplied query term
      q << "_query_:\"{!dismax qf=$qf_dismax pf=$pf_dismax}#{user_query}\""

    # Append the exclusion of Resources
      q << " AND NOT _query_:\"info\\\\:fedora/ldpd\\\\:Resource\""

    # Append the query responsible for adding the users discovery level
      permission_types = ["edit","discover","read"]
      field_queries = []
      embargo_query = ""
      permission_types.each do |type|
        field_queries << "_query_:\"#{type}_access_group_t:public\""
      end

      unless current_user.nil?
        # for roles
        RoleMapper.roles(current_user.login).each do |role|
          permission_types.each do |type|
            field_queries << "_query_:\"#{type}_access_group_t:#{role}\""
          end
        end
        # for individual person access
        permission_types.each do |type|
          field_queries << "_query_:\"#{type}_access_person_t:#{current_user.login}\""
        end
        if current_user.is_being_superuser?(session)
          permission_types.each do |type|
            field_queries << "_query_:\"#{type}_access_person_t:[* TO *]\""
          end
        end

        # if it is the depositor and it is under embargo, that is ok
        # otherwise if it not the depositor and it is under embargo, don't show it
        embargo_query = " OR  ((_query_:\"embargo_release_date_dt:[NOW TO *]\" AND  _query_:\"depositor_t:#{current_user.login}\") AND NOT (NOT _query_:\"depositor_t:#{current_user.login}\" AND _query_:\"embargo_release_date_dt:[NOW TO *]\"))"
      end
      
      # remove anything with an embargo release date in the future  
#embargo_query = " AND NOT _query_:\"embargo_release_date_dt:[NOW TO *]\"" if embargo_query.blank?
      field_queries << " NOT _query_:\"embargo_release_date_dt:[NOW TO *]\"" if embargo_query.blank?
      
      q << " AND (#{field_queries.join(" OR ")})"
      q << embargo_query 
    return q
  end


end
