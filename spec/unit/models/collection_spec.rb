require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Collection, type: :unit do

  before(:all) do

  end
  describe '.to_class_uri' do
    let(:to_class_uri) { Collection.to_class_uri }
    subject { to_class_uri }
    it do
      is_expected.to eql("info:fedora/pcdm:Collection")
    end
    context "is used as the value to look up the name of the model class" do
      subject { ActiveFedora::Model.classname_from_uri(to_class_uri) }
      it do
        is_expected.to eql ['Collection', 'pcdm']
      end
    end
    context "is used as the value to look up the model class" do
      subject { ActiveFedora::ContentModel.uri_to_model_class(to_class_uri) }
      it do
        is_expected.to be Collection
      end
    end
  end
  describe '#rdf_types!' do
    let(:aggregator) {
      agg = Collection.new
      allow(agg).to receive(:save).and_return(agg)
      agg
    }
    subject { aggregator.rdf_types! }
    it do
      expect(subject.relationships(:rdf_type)).to include(RDF::CUL.Aggregator.to_s)
      expect(subject.relationships(:rdf_type)).to include(RDF::PCDM.Collection.to_s)
      expect(subject.relationships(:rdf_type)).not_to include(RDF::PCDM.Object.to_s)
    end
  end
  describe '#to_solr' do
    context 'an aggregated resource has a fulltext index' do
      let(:aggregator) {
        agg = Collection.new
        allow(agg).to receive(:get_representative_generic_resource).and_return(part)
        allow(agg).to receive(:set_size_labels)
        agg
      }
      let(:fulltext) { ['fulltext'] }
      let(:part) {
        part = GenericResource.new
        allow(part).to receive(:to_solr).and_return("fulltext_tesim" => fulltext)
        part
      }
      subject { aggregator.to_solr }
      it do
        is_expected.not_to include('fulltext_tesim')
      end
    end
  end
end