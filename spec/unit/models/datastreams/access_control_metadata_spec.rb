require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Cul::Hydra::Datastreams::AccessControlMetadata, type: :unit do

  before(:all) do

  end
  let(:datastream) do
    ds = described_class.new
    ds.content = ds_content
    ds
  end
  describe '#to_solr' do
    let(:solr_doc) { datastream.to_solr }
    context "has permissions" do
      let(:ds_content) { fixture(File.join("CUL_ACCESS", "access-conditions.xml")) }
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
    context "is closed" do
      let(:ds_content) { fixture(File.join("CUL_ACCESS", "access-closed.xml")) }
      it "has access levels" do
        expect(solr_doc['access_control_levels_ssim'].sort).to eql(['Closed'])
      end
    end
    context "is open" do
      let(:ds_content) { fixture(File.join("CUL_ACCESS", "access-open.xml")) }
      it "has access levels" do
        expect(solr_doc['access_control_levels_ssim'].sort).to eql(['Public Access'])
      end
    end
  end
end