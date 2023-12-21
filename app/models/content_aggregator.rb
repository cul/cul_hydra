class ContentAggregator < GenericAggregator
  rdf_types(RDF::Cul.Aggregator)
  rdf_types(RDF::PCDM.Object)
  def to_solr(solr_doc = Hash.new, opts={})
    solr_doc = super

    Cul::Hydra::RisearchMembers.get_direct_members_with_datastream_pids(self.pid, 'fulltext').each do |pid|
      member = ActiveFedora::Base.find(pid)
      if member.is_a? GenericResource
        member_doc = member.to_solr
        unless member_doc["fulltext_tesim"].blank?
          solr_doc["fulltext_tesim"] = solr_doc.fetch("fulltext_tesim",[]) + member_doc["fulltext_tesim"]
        end
      end
    end

    solr_doc
  end
end
