require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Concept, type: :integration do
  before(:all) do
    renderer = ERB.new(fixture( File.join("FOXML", "concept.xml.erb")).read)
    description = fixture( File.join("BLOB", "dlc.md")).read
    @foxml = renderer.result(binding())
    open('tmp/cul_vmcvdnck2d.xml', 'wb') { |b| b.write(@foxml) }
    @pid = "cul:vmcvdnck2d"
  end
  before(:each) do
    ingest(@pid, StringIO.new(@foxml), true)
    @fixture_obj = ActiveFedora::Base.find(@pid)
  end
  after(:each) do
    ActiveFedora::Base.find(@pid, :cast=>false).delete
  end

  it "should produce the correct CModel PID" do
    @fixture_obj.cmodel_pid(@fixture_obj.class).should == "ldpd:Concept"
  end
  it "should have the slug available via accessor" do
  	expect(@fixture_obj.slug).to eql('catalog')
  	@fixture_obj.slug = 'other'
  	@fixture_obj.save
  	expect(ActiveFedora::Base.find(@pid).slug).to eql('other')
  end
  it "should index correctly" do
    @fixture_obj.update_index
    solr_doc = @fixture_obj.to_solr
    expect(solr_doc).to include("schema_image_ssim" => "info:fedora/cul:1c59zw3rf4")
    expect(solr_doc).to include("short_title_ssim" => "Digital Collections")
    expect(solr_doc).to include("source_ssim" => "https://dlc.library.columbia.edu/catalog")
    expect(solr_doc["abstract_ssim"]).to include("The Digital Library Collections (DLC)")
    expect(solr_doc["description_ssim"]).to eql("info:fedora/cul:vmcvdnck2d/description")
    expect(solr_doc["description_text_ssm"]).to include("Digital content in the DLC website comes almost exclusively from Columbia")
    expect(solr_doc).to include("restriction_ssim" => "Onsite")
    expect(solr_doc).to include("slug_ssim" => "catalog")
  end
end
