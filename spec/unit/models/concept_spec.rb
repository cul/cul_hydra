require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Concept, type: :unit do

  before(:all) do

  end
  describe '.to_class_uri' do
    let(:to_class_uri) { Concept.to_class_uri }
    subject { to_class_uri }
    it do
      is_expected.to eql("info:fedora/ldpd:Concept")
    end
    context "is used as the value to look up the name of the model class" do
      subject { ActiveFedora::Model.classname_from_uri(to_class_uri) }
      it do
        is_expected.to eql ['Concept', 'ldpd']
      end
    end
    context "is used as the value to look up the model class" do
      subject { ActiveFedora::ContentModel.uri_to_model_class(to_class_uri) }
      it do
        is_expected.to be Concept
      end
    end
  end
  describe '#rdf_types!' do
    let(:concept) {
      concept = Concept.new
      allow(concept).to receive(:save).and_return(concept)
      allow(concept).to receive(:members).and_return([])
      allow(concept).to receive(:get_representative_generic_resource)
      allow(concept).to receive(:set_size_labels)
      concept
    }
    subject { concept.rdf_types! }
    it do
      expect(subject.relationships(:rdf_type)).to include(RDF::CUL.Aggregator.to_s)
      expect(subject.relationships(:rdf_type)).to include(RDF::PCDM.Object.to_s)
      expect(subject.relationships(:rdf_type)).not_to include(RDF::PCDM.Collection.to_s)
    end
  end
  describe '#to_solr' do
    let(:concept) {
      concept = Concept.new
      allow(concept).to receive(:save).and_return(concept)
      allow(concept).to receive(:members).and_return([])
      allow(concept).to receive(:get_representative_generic_resource)
      allow(concept).to receive(:set_size_labels)
      concept
    }
    let(:solr_doc) { concept.to_solr }
    subject { solr_doc }
    context 'zero or one abstract values' do
      before {
        concept.abstract = abstract
      }
      let(:abstract) { 'test_value' }
      it do
        is_expected.to include('abstract_ssim' => abstract)
        concept.abstract = 'other_value'
        expect(concept.to_solr).to include('abstract_ssim' => 'other_value')
      end
      it 'fails with multiple abstracts set' do
        expect { concept.abstract = [abstract, 'other_value'] }.to raise_error
        concept.add_relationship(:abstract, 'other_value')
        expect(concept.valid?).to eql(false)
        expect(concept.errors[:abstract]).to eql(["abstract must have 0 or 1 values"])
      end
    end
    describe 'zero or one values for singular rels-ext attributes' do
      [:abstract, :restriction, :short_title, :slug, :source].each do |att|
        context att.to_s do
          let(att) { 'http://test_value' }
          before do
            concept.send(:"#{att}=", send(att))
          end
          it { expect(concept.send(att)).to eql(send(att)) }
          it do
            is_expected.to include("#{att}_ssim" => send(att))
            concept.send(:"#{att}=", 'http://other_value')
            expect(concept.to_solr).to include("#{att}_ssim" => 'http://other_value')
          end
        end
      end
    end
    context 'has an indexed description' do
      before {
        expect(concept.description_ds).to be_nil
        concept.description = description
        expect(concept.description_ds).not_to be_nil
      }
      context 'in ASCII' do
        let(:utf8) { '#Test Concept'.encode(Encoding::UTF_8) }
        let(:description) { utf8.encode(Encoding.find("US-ASCII")) }

        it do
          expect(concept.description).to eql(description)
          is_expected.to include('description_text_ssm' => utf8)
          expect(solr_doc['description_text_ssm'].encoding).to eql Encoding::UTF_8
        end
      end
      context 'in UTF8' do
        let(:description) { fixture( File.join("BLOB", "description-utf8.txt") ).read }
        it do
          expect(concept.description).to eql(description)
          is_expected.to include('description_text_ssm' => description)
          expect(solr_doc['description_text_ssm'].encoding).to eql Encoding::UTF_8
        end
      end
      context 'in cp1252' do
        let(:utf8) { fixture( File.join("BLOB", "description-utf8.txt") ).read }
        let(:description) { fixture( File.join("BLOB", "description-cp1252.txt") ).read }
        it 'encodes cp1252 input as utf8 for indexing' do
          expect(concept.description).to eql(description)
          is_expected.to include('description_text_ssm' => utf8)
          expect(solr_doc['description_text_ssm'].encoding).to eql Encoding::UTF_8
        end
      end
    end
  end
  describe "#description=" do
    let(:concept) {
      concept = Concept.new
      concept
    }
    it "when passed a nil or empty string value, removes the :description relationship and deletes the associated description datastream" do
      [nil, ''].each do |val|
        concept.description = 'Some description'
        expect(concept.description).to eq('Some description')
        expect(concept.relationships(:description).length).to eq(1)
        concept.description = val
        expect(concept.description).to eq(nil)
        expect(concept.relationships(:description).length).to eq(0)
        expect(concept.description_ds).to eq(nil)
      end
    end
  end
end
