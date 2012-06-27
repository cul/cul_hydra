require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "ContentAggregator" do
  
  before(:all) do
    @memberobj = ingest("test:si_agg", fixture( File.join("FOXML", "static-image-aggregator.xml")), true)
    @memberobj.send :update_index
  end
  
  before(:each) do
    @foxml = fixture( File.join("FOXML", "content-aggregator.xml"))
    ingest("test:c_agg", fixture( File.join("FOXML", "content-aggregator.xml")), true)
    @fixtureobj = ContentAggregator.find_by_identifier( "prd.custord.070103a")
    @fixtureobj.send :update_index
  end
  
  after(:each) do
    ActiveFedora::Base.find("test:c_agg").delete
  end

  after(:all) do
    ActiveFedora::Base.find("test:si_agg").delete
  end

  it "should produce the correct CModel PID" do
    @fixtureobj.cmodel_pid(@fixtureobj.class).should == "ldpd:ContentAggregator"
  end

  describe "descMetadata" do
    it "should have a descMetadata datastream" do
      @fixtureobj.datastreams["descMetadata"].class.name.should == "Cul::Scv::Hydra::Om::ModsDocument"
    end

    it "should be able to edit and push new data to Fedora" do
      new_value = "new.id.value"
      ds = @fixtureobj.datastreams["descMetadata"]
      ds.update_values({[:identifier] => new_value})
      ds.dirty?.should == true
      @fixtureobj.save
      updated = ContentAggregator.find(@fixtureobj.pid)
      ds.find_by_terms(:identifier).first.text.should == new_value
      updated.datastreams["descMetadata"].find_by_terms(:identifier).first.text.should == new_value
    end
  end

  describe "aggregation functions" do

    it "should be able to find its members/parts" do
      @fixtureobj.parts.length.should == 1
    end

  end
end
