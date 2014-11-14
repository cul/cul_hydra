require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'digest'
include Digest

def proxy_uri(proxy_in,proxy_for)
  RDF::Resource("urn:proxy:#{proxy_in ? MD5.hexdigest(proxy_in.to_s) : '' }:#{MD5.hexdigest(proxy_for.to_s)}")
end
#require 'rdf/nfo'
#require 'rdf/ore'
describe Ore::Proxy, type: :unit do
  
  before(:all) do
    expect(RDF::ORE.proxyIn.to_s).to eql("http://www.openarchives.org/ore/terms/proxyIn")
  end

  describe '#initialize' do
    let(:subject_uri) { RDF::URI("http://subject.uri") }
    let(:type_uri) { RDF::NFO['#Folder'] }
    let(:graph_uri) { RDF::URI("http://graph.context") }
    subject { Ore::Proxy.new(subject_uri,graph_uri) }
    it "should identify the subject" do
      expect(subject.id).to eql(proxy_uri(graph_uri,subject_uri))
    end
    it "should identify the type" do
      expect(subject.type.size).to eql(1)
      expect(subject.type).to include(RDF::ORE.Proxy)
    end
    it "should identify the proxied aggregation if given" do
      expect(subject.proxyIn.result.rdf_subject).to eql(graph_uri)
    end
  end
  describe 'property methods' do
    let(:subject_uri) { RDF::URI("http://subject.uri") }
    let(:type_uri) { RDF::NFO['#Folder'] }
    let(:graph_uri) { RDF::URI("http://graph.context") }
    subject { Ore::Proxy.new(subject_uri,graph_uri) }

    it 'should have the right properties defined' do
      properties = subject.send :properties
      predicates = {RDF::ORE.proxyIn => :proxyIn}
      predicates.each do |predicate, key|
        properties.each do |property, values|
          if values[:predicate] == predicate
            expect(key).to eql(values[:term])
          end
        end
      end
    end
    it 'should set and get properties' do
      expect(subject.proxyIn.result.rdf_subject).to eq(graph_uri)   
      subject.label = 'Comet in Moominland'
      subject.format = 'foormat'
      expect(subject.label).to eq 'Comet in Moominland'
      expect(subject.format).to eq('foormat')
      subject.index = 1
      expect(subject.index).to eq(1)
      subject_id = proxy_uri(RDF::URI("http://other.context"),subject_uri)
      subject.proxyIn= RDF::URI("http://other.context")
      expect(subject.proxyIn.result.rdf_subject).to eq(RDF::URI("http://other.context"))   
      expect(subject.id).to eq(subject_id)
    end
  end
  describe "#to_json" do
    let(:subject_uri) { RDF::URI("http://subject.uri") }
    let(:type_uri) { RDF::NFO['#Folder'] }
    let(:graph_uri) { RDF::URI("http://graph.context") }
    subject { Ore::Proxy.new(subject_uri,graph_uri) }
    it "should return a Hash" do
      expect(subject.to_json).to be_a(Hash)
      subject_id = proxy_uri(graph_uri,subject_uri)
      expect(subject.to_json['id']).to eql(subject_id.to_s)
      expect(subject.to_json['type_ssim']).to include(RDF::ORE.Proxy.to_s)
    end
    it "should identify the proxied aggregation" do
      expect(subject.to_json['proxyIn_ssi']).to eql(graph_uri.to_s)
    end
    it "should identify the proxied resource" do
      expect(subject.to_json['proxyFor_ssi']).to eql(subject_uri.to_s)
    end
    it "should identify the proxied resource" do
      subject.index = 1
      expect(subject.to_json['index_isi']).to eql("1")
    end
  end
end