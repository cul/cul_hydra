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

  context 'image rotation' do
    describe '#orientation / #orientation=' do
      it 'should properly set and get the correct image orientation' do
        o = GenericResource.new(pid:"gad:zooks")
        o.orientation = 90
        expect(o.orientation).to eql(90)
      end
      it 'should convert negative values to something in the 0 - 270 degree range' do
        o = GenericResource.new(pid:"gad:zooks")
        o.orientation = -90
        expect(o.orientation).to eql(270)
      end
      it 'should convert negative values over 270 to something in the 0 - 270 degree range' do
        o = GenericResource.new(pid:"gad:zooks")
        o.orientation = 450
        expect(o.orientation).to eql(90)
      end
      it 'should set the expected EXIF :orientation relationship value' do
        o = GenericResource.new(pid:"gad:zooks")
        o.orientation = 180
        expect(o.relationships(:orientation).first.to_s).to eql('bottom-right')
      end
      it 'should return 0 degrees if an image does not have an :orientation relationship defined' do
        o = GenericResource.new(pid:"gad:zooks")
        expect(o.orientation).to eql(0)
      end
      it 'should raise an exception if a non-right-angle value is set' do
        o = GenericResource.new(pid:"gad:zooks")
        expect { o.orientation = 91 }.to raise_error
      end
    end
    describe '#required_rotation_for_upright_display' do
      it "should return the correct number of rotation degrees after the #orientation method is used to set the orientation" do
        o = GenericResource.new(pid:"gad:zooks")
        o.orientation = 270
        expect(o.required_rotation_for_upright_display).to eql(90) # 90 degrees rotation required for upright display of a 270-degree-rotated image
      end
      it 'should return 0 degrees if an image does not have an :orientation relationship defined' do
        o = GenericResource.new(pid:"gad:zooks")
        expect(o.relationships(:orientation)).to eql([])
        expect(o.required_rotation_for_upright_display).to eql(0)
      end
    end

  end

end
