require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe GenericResource, type: :unit do

  before(:all) do

  end
  let(:o) { 
    o = GenericResource.new(pid:"gad:zooks")
    allow(o).to receive(:save).and_return(o)
    o
  }
  let(:fulltext) {
    ft = double('Datastream', content: 'foo', to_solr: {})
    ft
  }
  let(:datastream_ids) { o.datastreams.keys.map {|k| k.to_s}.sort }
  describe '#rdf_types!' do
    subject { o.rdf_types! }
    it do
      expect(subject.relationships(:rdf_type)).to include(RDF::CUL.Resource.to_s)
      expect(subject.relationships(:rdf_type)).to include(RDF::PCDM.Object.to_s)
      expect(subject.relationships(:rdf_type)).not_to include(RDF::PCDM.Collection.to_s)
      expect(subject.relationships(:rdf_type)).not_to include(RDF::CUL.Aggregator.to_s)
    end
  end
  context '#to_solr' do
    it 'should index the original path as full text if present' do
      o.add_relationship(:original_name,'/path/to/a/thing',true)
      doc = o.to_solr
      expect(doc['original_name_tesim']).to eql(['path to a thing'])
    end
    it 'should index the original path as full text if present' do
      o.datastreams['fulltext'] = fulltext
      fdoc = {"title_display_ssm" => ["Test title"]}
      doc = o.to_solr(fdoc, model_only: true)
      expect(doc['fulltext_tesim']).to eql(['Test title','foo'])
    end
    it 'has no access control data' do
      doc = o.to_solr({}, model_only: true)
      expect(doc['access_control_levels_ssim']).to eql(['Public Access'])
      expect(doc['access_control_permissions_bsi']).to eql(false)
    end
    it do
      expect(o.to_solr['datastreams_ssim']).to eql(datastream_ids)
    end
    context "it has accessControlMetadata" do
      let(:ds_content) { fixture(File.join("CUL_ACCESS", "access-conditions.xml")) }
      let(:solr_doc) { o.to_solr }
      before { o.datastreams['accessControlMetadata'].content = ds_content }

      it "has permitted affils" do
        expect(solr_doc['access_control_affiliations_ssim']).to eql(['LIB_role-ext-UnivSemArchives'])
      end
      it "has permitted locations" do
        expect(solr_doc['access_control_locations_ssim']).to eql(['http://id.library.columbia.edu/term/45487bbd-97ef-44b4-9468-dda47594bc60'])
      end
      it "has permitted date" do
        expect(solr_doc['access_control_embargo_dtsi']).to eql('2099-01-01')
      end
      it "has permissions flag" do
        expect(solr_doc['access_control_permissions_bsi']).to eql(true)
      end
      it "has access levels" do
        expect(solr_doc['access_control_levels_ssim'].sort).to eql(['Embargoed','On-site Access','Specified Group/UNI Access'])
      end
    end
  end

  context 'image rotation' do
    describe '#orientation / #orientation=' do
      it 'should properly set and get the correct image orientation' do
        o.orientation = 90
        expect(o.orientation).to eql(90)
      end
      it 'should convert negative values to something in the 0 - 270 degree range' do
        o.orientation = -90
        expect(o.orientation).to eql(270)
      end
      it 'should convert negative values over 270 to something in the 0 - 270 degree range' do
        o.orientation = 450
        expect(o.orientation).to eql(90)
      end
      it 'should set the expected EXIF :orientation relationship value' do
        o.orientation = 180
        expect(o.relationships(:orientation).first.to_s).to eql('bottom-right')
      end
      it 'should return 0 degrees if an image does not have an :orientation relationship defined' do
        expect(o.orientation).to eql(0)
      end
      it 'should raise an exception if a non-right-angle value is set' do
        expect { o.orientation = 91 }.to raise_error
      end
    end
    describe '#required_rotation_for_upright_display' do
      it "should return the correct number of rotation degrees after the #orientation method is used to set the orientation" do
        o.orientation = 270
        expect(o.required_rotation_for_upright_display).to eql(90) # 90 degrees rotation required for upright display of a 270-degree-rotated image
      end
      it 'should return 0 degrees if an image does not have an :orientation relationship defined' do
        expect(o.relationships(:orientation)).to eql([])
        expect(o.required_rotation_for_upright_display).to eql(0)
      end
    end

    describe '#service_datastream' do
      let(:service_ds) { 'svc' }
      let(:ds_location) { 'file:/gad/zooks/service/file' }
      let(:solr_field) { 'service_dslocation_ss' }
      subject { o.service_datastream }
      context 'object has a service datastream and RELS-INT to indicate it' do
        before do
          s = RDF::URI.new("info:fedora/gad:zooks/svc")
          o.rels_int.add_relationship(s,:format_of,RDF::URI.new("#{o.internal_uri}/content"))
          o.rels_int.add_relationship(s,:rdf_type,"http://pcdm.org/use#ServiceFile")
          ds = o.create_datastream(ActiveFedora::Datastream, service_ds)
          ds.dsLocation = ds_location
          o.add_datastream(ds)
        end
        it { is_expected.not_to be_nil }
        it { expect(subject.dsid).to eql(service_ds) }
        it { expect(o.to_solr[solr_field]).to eql(ds_location)}
      end
      context 'object has RELS-INT to indicate service datastream but no datastream' do
        before do
          s = RDF::URI.new("info:fedora/gad:zooks/svc")
          o.rels_int.add_relationship(s,:format_of,RDF::URI.new("#{o.internal_uri}/content"))
          o.rels_int.add_relationship(s,:rdf_type,"http://pcdm.org/use#ServiceFile")
        end
        it { is_expected.to be_nil }
        it { expect(o.to_solr[solr_field]).to be_nil }
      end              
    end

    describe '#closed?' do
      before { o.datastreams['accessControlMetadata'].content = ds_content }
      let(:actual) { o.closed? }
      context 'no access control metadata' do
        let(:ds_content) { "" }
        it { expect(actual).to be false }
      end
      context 'access control metadata is not closed' do
        let(:ds_content) { fixture(File.join("CUL_ACCESS", "access-conditions.xml")) }
        it { expect(actual).to be false }
      end
      context 'access control metadata includes closed' do
        let(:ds_content) { fixture(File.join("CUL_ACCESS", "access-closed.xml")) }
        it { expect(actual).to be true }
      end
    end
  end

end
