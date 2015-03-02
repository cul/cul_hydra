require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe GenericResource, type: :unit do

  before(:all) do

  end
  context '#to_solr' do
    it 'should index the original path as full text if present' do
      o = GenericResource.new(pid:"lol:wut")
      o.add_relationship(:original_name,'/path/to/a/thing',true)
      doc = o.to_solr
      expect(doc['original_name_tesim']).to eql(['path to a thing'])
    end
    it 'should index the original path as full text if present' do
      o = GenericResource.new(pid:"lol:wut")
      ft = double('Datastream')
      o.datastreams['fulltext'] = ft
      allow(ft).to receive(:content).and_return('foo')
      allow(ft).to receive(:to_solr).and_return({})
      fdoc = {"title_display_ssm" => ["Test title"]}
      doc = o.to_solr(fdoc, model_only: true)
      expect(doc['fulltext_tesim']).to eql(['Test title','foo'])
    end
  end
end
