require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'om'
class ControllerHarness
  def self.before_filter(*args)
  end
end

class TermsHarness < ControllerHarness
  include Cul::Scv::Hydra::Controllers::Terms
  
  def initialize(field_name)
    @solr_name = field_name || "title_0_t"
  end
  
  def params
    {}
  end
  
  def field_key
    field_key_from(@solr_name, Cul::Scv::Hydra::Om::ModsDocument.terminology)
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

describe "Cul::Scv::Hydra::Controllers::Terms" do
  
  before(:all) do
  end
  
  before(:each) do
    @fixture = TermsHarness.new(TermsHarness.field_name_for([:title]))
  end
  
  after(:all) do

  end
  
  it "should round-trip term name to pointer array" do
    pointerses = [[:title]]
    pointerses.each do |pointers|
      fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
      fixture.field_key.should == pointers
    end
  end
  it "should round-trip term names with underscores to pointer array" do
    pointerses = [[:main_title_info,:main_title]]
    pointerses.each do |pointers|
      fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
      fixture.field_key.should == pointers
    end
  end
  it "should round-trip indexed term names to pointer array" do
    pointerses = [[{:title=>0}]]
    pointerses.each do |pointers|
      fixture = TermsHarness.new(TermsHarness.field_name_for(pointers))
      fixture.field_key.should == pointers
    end
  end
end