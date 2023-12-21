require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AdministrativeSet, type: :unit do

  before(:all) do

  end
  describe '.to_class_uri' do
    let(:to_class_uri) { AdministrativeSet.to_class_uri }
    subject { to_class_uri }
    it do
      is_expected.to eql("info:fedora/pcdm:AdministrativeSet")
    end
    context "is used as the value to look up the name of the model class" do
      subject { ActiveFedora::Model.classname_from_uri(to_class_uri) }
      it do
        is_expected.to eql ['AdministrativeSet', 'pcdm']
      end
    end
    context "is used as the value to look up the model class" do
      subject { ActiveFedora::ContentModel.uri_to_model_class(to_class_uri) }
      it do
        is_expected.to be AdministrativeSet
      end
    end
  end
  describe '#rdf_types!' do
    let(:aggregator) {
      agg = AdministrativeSet.new
      allow(agg).to receive(:save).and_return(agg)
      agg
    }
    subject { aggregator.rdf_types! }
    it do
      expect(subject.relationships(:rdf_type)).to include(RDF::Cul.Aggregator.to_s)
      expect(subject.relationships(:rdf_type)).to include(RDF::PCDM.AdministrativeSet.to_s)
      expect(subject.relationships(:rdf_type)).not_to include(RDF::PCDM.Object.to_s)
    end
  end
  describe '#to_solr' do
    let(:aggregator) {
      agg = AdministrativeSet.new
      allow(agg).to receive(:save).and_return(agg)
      agg
    }
    subject { aggregator }
    it do
      expect(subject.to_solr).to be_a(Hash)
    end
  end
end