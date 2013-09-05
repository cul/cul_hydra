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
    @containerobj = StaticImageAggregator.find( "test:si_agg")
    @containerobj.send :update_index
    @fixtureobj = Resource.find("test:thumb_image")
  end
  
  after(:each) do
    @fixtureobj.delete
    @containerobj.delete
  end

  after(:all) do
    ActiveFedora::Base.find("test:c_agg").delete
    ActiveFedora::Base.find("ldpd:StaticImageAggregator").delete
    ActiveFedora::Base.find("ldpd:ContentAggregator").delete
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
      ds.update_values({[:dc_identifier] => new_value})
      ds.changed?.should == true
      @fixtureobj.save
      ds.changed?.should == false
      updated = Resource.find(@fixtureobj.pid)
      found = false
      ds.find_by_terms(:dc_identifier).each { |node|
        found ||= node.text == new_value
      }
      found.should == true
      found = false
      updated.datastreams["DC"].find_by_terms(:dc_identifier).each { |node|
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
      test = Resource.find(@newobj.pid)
      test.datastreams['CONTENT'].nil?.should be_false
      (test.datastreams['CONTENT'].is_a? ActiveFedora::Datastream).should be_true
    end

    it "should be able to find its sampling type" do
      pred = ActiveFedora::Predicates.find_graph_predicate(:resolution_unit)
      puts "#{pred.class} : #{pred}"
      found = 0
      @newobj.relationships(pred).each { |object|
        found += 1
        object.should == RDF::Literal.new('1')
      }
      found.should == 1
    end

    it "should be able to find its width" do
      pred = ActiveFedora::Predicates.find_graph_predicate(:exif_image_width)
      puts "#{pred.class} : #{pred}"
      @newobj.relationships(pred).length.should == 1
    end

    it "should be able to find its extent" do
      pred = ActiveFedora::Predicates.find_graph_predicate(:extent)
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
