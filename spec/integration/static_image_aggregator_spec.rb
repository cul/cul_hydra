require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
#require 'mediashelf/active_fedora_helper'

describe "StaticImageAggregator" do
  before(:all) do
    ingest("ldpd:ContentAggregator", fixture( File.join("FOXML", "content-cmodel.xml")), true)
    @parentobj = ingest("test:c_agg", fixture( File.join("FOXML", "content-aggregator.xml")), true)
    @parentobj.send :update_index
    ingest("ldpd:StaticImageAggregator", fixture( File.join("FOXML", "image-cmodel.xml")), true)
    @cmodel = ingest("ldpd:StaticImageAggregator", fixture( File.join("FOXML", "image-cmodel.xml")), true)
  end
  
  before(:each) do
    @foxml = fixture( File.join("FOXML", "static-image-aggregator.xml"))
    ingest("test:si_agg", fixture( File.join("FOXML", "static-image-aggregator.xml")), true)
    ingest("test:thumb_image", fixture( File.join("FOXML", "resource-thumb.xml")), true)
    ingest("test:screen_image", fixture( File.join("FOXML", "resource-screen.xml")), true)
    ingest("test:max_image", fixture( File.join("FOXML", "resource-max.xml")), true)
    @fixtureobj = StaticImageAggregator.find( "test:si_agg")
    @fixtureobj.send :update_index
    Resource.find("test:thumb_image").send :update_index
    Resource.find("test:screen_image").send :update_index
    Resource.find("test:max_image").send :update_index
  end
  
  after(:each) do
    @fixtureobj.delete
    ActiveFedora::Base.find("test:thumb_image", :cast=>false).delete
    ActiveFedora::Base.find("test:screen_image", :cast=>false).delete
    ActiveFedora::Base.find("test:max_image", :cast=>false).delete
  end

  after(:all) do
    ActiveFedora::Base.find("test:c_agg", :cast=>false).delete
    ActiveFedora::Base.find("ldpd:StaticImageAggregator", :cast=>false).delete
    ActiveFedora::Base.find("ldpd:ContentAggregator", :cast=>false).delete
  end

  it "should be detectable by ActiveFedora" do
    Kernel.const_get('StaticImageAggregator').is_a?(Class).should == true
    Module.const_get('StaticImageAggregator').is_a?(Class).should == true
    obj = ActiveFedora::Base.find("test:si_agg", :cast=>false)
    ActiveFedora::ContentModel.models_asserted_by(obj).each { |m_uri|
      m_class = ActiveFedora::ContentModel.uri_to_model_class(m_uri)
    }
    the_model = ActiveFedora::ContentModel.known_models_for( obj ).first
    the_model.should == StaticImageAggregator
  end

  it "should produce the correct CModel PID" do
    @fixtureobj.cmodel_pid(@fixtureobj.class).should == "ldpd:StaticImageAggregator"
  end

  describe "rightsMetadata" do
    it "should have a rightsMetadata datastream" do
      @fixtureobj.datastreams["rightsMetadata"].class.name.should ==
       "Hydra::Datastream::RightsMetadata"
    end
    it "should have a permissions method" do
      @fixtureobj.datastreams["rightsMetadata"].respond_to?(:permissions).should == true
    end
  end

  describe "DC" do
    it "should have a DC datastream" do
      @fixtureobj.datastreams["DC"].class.should == Cul::Scv::Hydra::Datastreams::DCMetadata
    end

    it "should be able to edit and push new data to Fedora" do
      new_value = "new.test.id.value"
      ds = @fixtureobj.datastreams["DC"]
      ds.update_indexed_attributes({[:dc_identifier] => new_value})
      ds.changed?.should be_true
      @fixtureobj.save
      ds.changed?.should be_false
      updated = StaticImageAggregator.find(@fixtureobj.pid)
      found = false
      ds.find_by_terms(:dc_identifier).each { |node|
        found ||= node.text == new_value
      }
      found.should be_true
      found = false
      updated.datastreams["DC"].find_by_terms(:dc_identifier).each { |node|
        found ||= node.text == new_value
      }
      found.should be_true
    end
  end

  describe "aggregation functions" do

    it "should be able to find its members/parts" do
      @fixtureobj.parts.to_a.length.should == 2
    end

    it "should be able to add members/parts" do
      obj = ActiveFedora::Base.find("test:thumb_image", :cast=>false)
      @fixtureobj.add_member(obj)
      @fixtureobj.parts.to_a.length.should == 3
    end

    it "should be able to find its containers" do
      @fixtureobj.containers.to_a.length.should == 1
    end
  end
end
