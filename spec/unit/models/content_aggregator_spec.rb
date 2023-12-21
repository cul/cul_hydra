require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe ContentAggregator, type: :unit do

  before(:all) do

  end
  describe '.to_class_uri' do
    let(:to_class_uri) { ContentAggregator.to_class_uri }
    subject { to_class_uri }
    it do
      is_expected.to eql("info:fedora/ldpd:ContentAggregator")
    end
    context "is used as the value to look up the name of the model class" do
      subject { ActiveFedora::Model.classname_from_uri(to_class_uri) }
      it do
        is_expected.to eql ['ContentAggregator', 'ldpd']
      end
    end
    context "is used as the value to look up the model class" do
      subject { ActiveFedora::ContentModel.uri_to_model_class(to_class_uri) }
      it do
        is_expected.to be ContentAggregator
      end
    end
  end
  describe '#rdf_types!' do
    let(:aggregator) {
      agg = ContentAggregator.new
      allow(agg).to receive(:save).and_return(agg)
      agg
    }
    subject { aggregator.rdf_types! }
    it do
      expect(subject.relationships(:rdf_type)).to include(RDF::Cul.Aggregator.to_s)
      expect(subject.relationships(:rdf_type)).to include(RDF::Pcdm.Object.to_s)
      expect(subject.relationships(:rdf_type)).not_to include(RDF::Pcdm.Collection.to_s)
    end
  end
  describe '#to_solr' do
    context 'an aggregated resource has a fulltext index' do
      let(:aggregator) {
        agg = ContentAggregator.new
        allow(Cul::Hydra::Fedora.repository).to receive(:find_by_itql).and_return(risearch_response)
        allow(agg).to receive(:get_representative_generic_resource).and_return(part)
        allow(agg).to receive(:set_size_labels)
        agg
      }
      let(:fulltext) { ['fulltext'] }
      let(:datastream_ids) { aggregator.datastreams.keys.map {|k| k.to_s}.sort }
      let(:risearch_response) { '{"results":[{"pid":"info:fedora/ldpd:123", "k0":"1"}]}' }
      let(:part) {
        part = GenericResource.new
        allow(part).to receive(:to_solr).and_return("fulltext_tesim" => fulltext)
        part
      }
      subject { aggregator.to_solr }
      before do
        allow(ActiveFedora::Base).to receive(:find).with('ldpd:123').and_return(part)
      end
      it do
        is_expected.to include('fulltext_tesim')
        expect(subject['fulltext_tesim']).to eql(fulltext)
      end
      it do
        expect(subject['datastreams_ssim']).to eql(datastream_ids)
      end
    end
  end
end
