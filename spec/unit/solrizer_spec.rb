require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Scv::Hydra::Solrizer::TerminologyBasedSolrizer", type: :unit do
  
  before(:all) do
        
  end
  
  before(:each) do
    @mods_fixture = descMetadata(@mock_inner, fixture( File.join("CUL_MODS", "mods-001.xml")))
    @solr_fixture = YAML::load( fixture( File.join("CUL_SOLR", "mods-001.yml") ) )
  end
  
  after(:all) do

  end
  
  it "should automatically include the necessary modules" do
    skip "identification of modules"
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
        actual = (solr[key].is_a? Array) ? solr[key].sort : [solr[key]]
        expected = (value_array.is_a? Array) ? value_array.sort : [value_array]
        puts "BAD MATCH: #{key} got: #{solr[key].inspect} expected: #{value_array.inspect}" if actual != expected
        if actual != expected
          fails << key
          puts "<< #{actual.inspect}" if solr[key]
          puts ">> #{expected.inspect}"
        end
        #solr[key].should == value_array
      }
      fails.should == []
    end

    it "should produce equivalent xml when built up programatically" do
      skip "passing hash comparison"
    end
  end
   
end
