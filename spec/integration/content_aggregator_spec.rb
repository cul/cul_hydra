require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ContentAggregator, type: :integration do

  before(:each) do
    @foxml = fixture( File.join("FOXML", "content-aggregator.xml"))
    ingest("test:c_agg", fixture( File.join("FOXML", "content-aggregator.xml")), true)
    @memberobj = ingest("test:si_agg", fixture( File.join("FOXML", "static-image-aggregator.xml")), true)
    @memberobj.send :update_index
    @fixtureobj = ContentAggregator.search_repo.find_by!(identifier: "prd.custord.070103a")
    @fixtureobj.send :update_index
  end

  after(:each) do
    ActiveFedora::Base.find("test:si_agg", :cast=>false).delete
    ActiveFedora::Base.find("test:c_agg", :cast=>false).delete
  end

  it "should produce the correct CModel PID" do
    @fixtureobj.cmodel_pid(@fixtureobj.class).should == "ldpd:ContentAggregator"
  end

  describe "aggregation functions" do

    it "should be able to find its members/parts" do
      expect(@memberobj.containers.collect {|x| x.pid}).to eql [@fixtureobj.pid]
      expect(@fixtureobj.members.collect {|x| x['id']}).to eql [@memberobj.pid]
      expect(@fixtureobj.parts.collect {|x| x.pid}).to eql [@memberobj.pid]
    end

  end

  describe "descMetadata" do
    it "should have a descMetadata datastream" do
      expect(@fixtureobj.datastreams["descMetadata"]).to be_a Cul::Hydra::Datastreams::ModsDocument
    end

    it "should be able to edit and push new data to Fedora" do
      new_value = "new.id.value"
      ds = @fixtureobj.datastreams["descMetadata"]
      ds.update_values({[:identifier] => new_value})
      expect(ds.changed?).to be_true
      @fixtureobj.save
      updated = ContentAggregator.find(@fixtureobj.pid)
      expect(ds.find_by_terms(:identifier).first.text).to eql new_value
      expect(updated.datastreams["descMetadata"].find_by_terms(:identifier).first.text).to eql new_value
    end
  end

  describe "structMetadata" do
    it "should have a default, stubbed structMetadata datastream" do
      ds = @fixtureobj.datastreams["structMetadata"]
      expect(ds).to be_a(Cul::Hydra::Datastreams::StructMetadata)
      ds.changed?.should be_falsey
      expect(@fixtureobj.to_solr[:structured_bsi]).to eql 'false'
    end

    it "should correctly index as structured if there is structMetadata content" do
      ds = @fixtureobj.datastreams["structMetadata"]
      ds.label = "Test Label"
      ds.changed?.should be_true
      puts "structMetadata: #{ds.content}"
      ds.save
      expect(@fixtureobj.to_solr[:structured_bsi]).to eql 'true'
    end
  end

end
