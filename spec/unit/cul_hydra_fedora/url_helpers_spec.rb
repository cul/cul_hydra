require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))
#require 'active_fedora'
describe Cul::Hydra::Fedora::UrlHelperBehavior, type: :unit do
  let (:base_url) { "http://localhost/repotest"}
  let (:config) { double('Configurator')}
  let (:fedora_config) { {url: base_url(), user: 'lol', password: 'wut'}}
  before do
    class TestUrls
      include Cul::Hydra::Fedora::UrlHelperBehavior
    end
    ActiveFedora.configurator = config
    allow(config).to receive(:fedora_config).and_return(fedora_config)
    ActiveFedora.instance_variable_set(:@fedora_config,nil)
  end
  after do
    Object.send :remove_const, :TestUrls
    ActiveFedora.configurator = nil
  end
  subject { TestUrls.new }
  it "should repond to #fedora_url with configured url" do
    expect(subject.fedora_url).to eql(base_url)
  end
  describe '#pid_for_url' do
    {'info:fedora/lol:wut' => 'lol:wut', 'lol:wut' => 'lol:wut'}.each do |k,v|
      it "should map #{k} to #{v}" do
        expect(subject.pid_for_url(k)).to eql(v)
      end
    end
  end
  describe '#fedora_object_url' do
    {'info:fedora/lol:wut' => "/objects/lol:wut",
      'lol:wut' => "/objects/lol:wut"}.each do |k,v|
      it "should map #{k} to #{v}" do
        expect(subject.fedora_object_url(k)).to eql(base_url + v)
      end
    end
  end
  describe '#fedora_ds_url' do
    {['info:fedora/lol:wut','foo'] => "/objects/lol:wut/datastreams/foo",
      ['lol:wut','foo'] => "/objects/lol:wut/datastreams/foo"}.each do |k,v|
      it "should map #{k} to #{v}" do
        expect(subject.fedora_ds_url(*k)).to eql(base_url + v)
      end
    end
  end
  describe '#fedora_method_url' do
    {['info:fedora/lol:wut','foo'] => "/objects/lol:wut/methods/foo",
      ['lol:wut','foo'] => "/objects/lol:wut/methods/foo"}.each do |k,v|
      it "should map #{k} to #{v}" do
        expect(subject.fedora_method_url(*k)).to eql(base_url + v)
      end
    end
  end
  describe '#fedora_risearch_url' do
    it do
      expect(subject.fedora_risearch_url).to eql("#{base_url}/risearch")
    end
  end
  context 'test deprecated form' do
    before do
      class TestOld
        include Cul::Hydra::Fedora::UrlHelperBehavior
      end
    end
    after do
      Object.send :remove_const, :TestOld
    end
    subject { TestUrls.new }
    it "should repond to #fedora_url with configured url" do
      expect(subject.fedora_url).to eql(base_url)
    end
  end    

end