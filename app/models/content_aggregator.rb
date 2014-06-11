class ContentAggregator < GenericAggregator

  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super(solr_doc, opts)
    solr_doc["cul_number_of_members_isi"] = Cul::Scv::Hydra::RisearchMembers.get_direct_member_pids(pid).length
    solr_doc
  end

end
