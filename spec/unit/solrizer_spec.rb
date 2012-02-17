require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer" do
  
  before(:all) do
        
  end
  
  before(:each) do
    @mods_fixture = Cul::Scv::Hydra::Om::ModsDocument.from_xml( fixture( File.join("CUL_MODS", "mods-001.xml") ) )
    @solr_fixture = YAML::load( fixture( File.join("CUL_SOLR", "mods-001.yml") ) )
  end
  
  after(:all) do

  end
  
  it "should automatically include the necessary modules" do
    pending "identification of modules"
    #Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer.included_modules.should include(OM::XML::Validation)
  end
  
  describe ".to_solr" do
    it "should serialize new documents to xml" do
      solr = @mods_fixture.to_solr
      debug = solr.dup
      debug.delete_if { |k, v| k.to_s =~ /^mods_.*/ }
      debug.delete_if { |k, v| k.to_s =~ /^top_.*/ }
      fails = []
      @solr_fixture.each { |key, value_array|
        puts "BAD MATCH: #{key} solr: #{solr[key].inspect} value: #{value_array.inspect}" if !solr[key] or solr[key].sort != value_array.sort
        fails << key if !solr[key] or solr[key].sort != value_array.sort
        #solr[key].should == value_array
      }
      fails.should == []
    end

    it "should produce equivalent xml when built up programatically" do
      pending "passing hash comparison"
    end
  end
   
end
