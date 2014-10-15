require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
class ControllerHarness
  def self.before_filter(*args)
  end
end

class TermsHarness < ControllerHarness
  include Cul::Scv::Hydra::Controllers::Terms
  
  def initialize(field_name)
    @field_name = field_name
  end
  
  def params
    {}
  end
  
  def field_key
    field_key_from(@field_name, TestTerms.terminology)
  end
  
  # this is copied directly from Hydra::HydraFedoraMetadataHelperBehavior
  def self.field_name_for(field_key)
    if field_key.kind_of?(Array)
      return OM::XML::Terminology.term_hierarchical_name(*field_key)
    else
      return field_key.to_s
    end
  end
end

class TestTerms < ActiveFedora::OmDatastream
  set_terminology do |t|
    t.root(:path=>"root")
    
    t.title_info(:path=>'titleInfo'){
      t.title_info_title(:path=>"title")
    }
    
    t.container(:path=>"container"){
      t.container_title_info(:path=>'titleInfo'){
        t.container_title(:path=>'title')
      }
    }
    t.title(:proxy=>[:root,:title_info,:title])
  end
end

describe "Cul::Scv::Hydra::Controllers::Terms", type: :unit do
  
  before(:all) do
  end
  
  before(:each) do
    @fixture = TermsHarness.new(TermsHarness.field_name_for([:title]))
  end
  
  after(:all) do

  end
  
  it "should round-trip term name to pointer array" do
    pointers = [:title]
    fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
    fixture.field_key.should == pointers
  end
  it "should round-trip term names with underscores to pointer array" do
    pointers = [:title_info,:title_info_title]
    fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
    fixture.field_key.should == pointers
  end
  it "should round-trip indexed term names to pointer array" do
    pointers = [{:title=>0}]
    fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
    fixture.field_key.should == pointers
  end
  it "should round-trip indexed term names with underscores to pointer array" do
    pointers = [{:container=>0},{:container_title_info=>0},:container_title]
    fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
    fixture.field_key.should == pointers
  end
  it "should round-trip unevenly indexed term names with underscores to pointer array" do
    pointers = [:container,{:container_title_info=>0},:container_title]
    fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
    fixture.field_key.should == pointers
  end
end