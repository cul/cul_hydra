require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Resource" do
  
  before(:all) do
    ingest("ldpd:ContentAggregator", fixture( File.join("FOXML", "content-cmodel.xml")), true)
    ingest("ldpd:StaticImageAggregator", fixture( File.join("FOXML", "image-cmodel.xml")), true)
    @parentobj = ingest("test:c_agg", fixture( File.join("FOXML", "content-aggregator.xml")), true)
    @parentobj.send :update_index
    ingest("ldpd:StaticImageAggregator", fixture( File.join("FOXML", "image-cmodel.xml")), true)
  end
  
  before(:each) do
    @foxml = fixture( File.join("FOXML", "static-image-aggregator.xml"))
    ingest("test:si_agg", fixture( File.join("FOXML", "static-image-aggregator.xml")), true)
    ingest("test:thumb_image",fixture( File.join("FOXML", "resource-thumb.xml")), true)
    @containerobj = StaticImageAggregator.load_instance( "test:si_agg")
    @containerobj.send :update_index
    @fixtureobj = Resource.load_instance("test:thumb_image")
  end
  
  after(:each) do
    @fixtureobj.delete
    @containerobj.delete
  end

  after(:all) do
    ActiveFedora::Base.load_instance("test:c_agg").delete
    ActiveFedora::Base.load_instance("ldpd:StaticImageAggregator").delete
    ActiveFedora::Base.load_instance("ldpd:ContentAggregator").delete
  end

  it "should produce the correct CModel PID" do
    @containerobj.cmodel_pid(@fixtureobj.class).should == "ldpd:Resource"
  end

  describe "DC" do
    it "should have a DC datastream" do
      @fixtureobj.datastreams["DC"].class.name.should == "Cul::Scv::Hydra::Om::DCMetadata"
    end

    it "should be able to edit and push new data to Fedora" do
      new_value = "new.id.value"
      ds = @fixtureobj.datastreams["DC"]
      ds.update_values({[:identifier] => new_value})
      ds.dirty?.should == true
      @fixtureobj.save
      ds.dirty?.should == false
      updated = Resource.load_instance(@fixtureobj.pid)
      found = false
      ds.find_by_terms(:identifier).each { |node|
        found ||= node.text == new_value
      }
      found.should == true
      found = false
      updated.datastreams["DC"].find_by_terms(:identifier).each { |node|
        found ||= node.text == new_value
      }
      found.should == true
    end
  end

  describe "relationships" do
    before(:all) do
      blob = fixture( File.join("BLOB", "test001.jpg"))
      @newobj = Resource.new(:pid=>"test:resource")
      @newobj.save
      @newobj.add_content_blob(blob, :file_name=>"test001.jpg")
      @newobj.save
    end

    after(:all) do
      @newobj.delete
    end

    it "should have a datastream called CONTENT" do
      test = Resource.load_instance(@newobj.pid)
      test.datastreams['CONTENT'].nil?.should be_false
      (test.datastreams['CONTENT'].is_a? ActiveFedora::Datastream).should be_true
    end

    it "should be able to find its sampling type" do
      pred = ActiveFedora::Predicates.find_graph_predicate(:sampling_unit)
      found = 0
      query = RDF::Query.new({:subject=>{RDF::URI(pred) => :object }})
      @newobj.relationships(RDF::URI(pred)).each { |object|
        found += 1
        object.should == RDF::URI('http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/ASSESSMENT/NoAbsoluteSampling')
      }
      found.should == 1
    end

    it "should be able to find its width" do
      @newobj.relationships(RDF::URI("http://purl.oclc.org/NET/CUL/RESOURCE/STILLIMAGE/BASIC/imageWidth")).length.should == 1
    end

    it "should be able to find its extent" do
      pred = ActiveFedora::Predicates.find_graph_predicate(:extent)
      query = RDF::Query.new({:subject=>{pred => :object }})
      values = @newobj.relationships(pred)
      found = 0
      values.each { |value|
        found += 1
        value.to_s.should == '15138'
      }
      found.should == 1
    end
  end
end
