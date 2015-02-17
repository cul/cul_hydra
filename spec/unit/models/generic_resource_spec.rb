require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe GenericResource, type: :unit do

  before(:all) do

  end
  context '#to_solr' do
    it 'should index the original path as full text if present' do
      o = GenericResource.new(pid:"lol:wut")
      o.add_relationship(:original_name,'/path/to/a/thing',true)
      doc = o.to_solr
      expect(doc['fulltext_tesim']).to eql(['path to a thing'])
    end
  end
end
