require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata" do
  
  before(:all) do
        
  end
  
  before(:each) do
    @mock_inner = mock('inner object')
    @mock_inner.stubs(:"new_record?").returns(false)
    @mock_repo = mock('repository')
    @mock_ds = mock('datastream')
    @mock_repo.stubs(:config).returns({})
    #@mock_repo.stubs(:datastream_dissemination=>'My Content')
    @mock_inner.stubs(:repository).returns(@mock_repo)
    @mock_inner.stubs(:pid)
    @rv_fixture = fixture( File.join("STRUCTMAP", "structmap-recto.xml")).read
    @rv_doc = Nokogiri::XML::Document.parse(@rv_fixture)
    @struct_fixture = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.from_xml(@rv_fixture)
    @seq_fixture = fixture( File.join("STRUCTMAP", "structmap-seq.xml")).read
    @seq_doc = Nokogiri::XML::Document.parse(@seq_fixture)
  end

  describe ".new " do
    it "should create a new DS when no structMetadata exists" do
      @mock_repo.stubs(:datastream_profile).returns({})
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(@mock_inner, 'structMetadata')
      # it should have the default content
      test_obj.ng_xml.should be_equivalent_to Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.xml_template
      # but it shouldn't be "saveable" until you do something
      test_obj.new?.should be_true
      test_obj.changed?.should be_false
      # like assigning an attribute value
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(@mock_inner,
       'structMetadata', :label=>'TEST LABEL')
      test_obj.new?.should be_true
      test_obj.changed?.should be_true
    end
  end

  describe ".create_div_node " do
	  it "should build a simple R/V structure" do
	  	built = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(nil, 'structMetadata', label:'Sides', type:'physical')
	  	built.create_div_node(nil, {:order=>"1", :label=>"Recto", :contentids=>"rbml_css_0702r"})
	  	built.create_div_node(nil, {:order=>"2", :label=>"Verso", :contentids=>"rbml_css_0702v"})
	  	built.ng_xml.should be_equivalent_to(@rv_doc)
	  end

    it "should build a simple sequence structure" do
      built = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(nil, 'structMetadata', label:'Sequence', type:'logical')
      built.create_div_node(nil, {:order=>"1", :label=>"Item 1", :contentids=>"prd.custord.060108.001"})
      built.create_div_node(nil, {:order=>"2", :label=>"Item 2", :contentids=>"prd.custord.060108.002"})
      built.create_div_node(nil, {:order=>"3", :label=>"Item 3", :contentids=>"prd.custord.060108.003"})
      built.ng_xml.should be_equivalent_to(@seq_doc)
    end

    it "should work if the parent node has its own NS prefix" do
      test_src = "<foo:structMap xmlns:foo=\"http://www.loc.gov/METS/\" />"
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.from_xml test_src
      test_div = test_obj.create_div_node
      test_div.namespace.prefix.should == "foo"
    end

    it "should work if the parent node is in the default NS" do
      test_src = "<structMap xmlns=\"http://www.loc.gov/METS/\" />"
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.from_xml test_src
      test_div = test_obj.create_div_node
      test_div.namespace.prefix.should be_nil
    end
  end

  describe ".content= " do
    it "should parse existing structMetadata content appropriately" do
      @mock_repo.stubs(:datastream_profile).returns({:dsID => 'structMetadata'})
      @mock_repo.stubs(:datastream_dissemination=>@rv_fixture)
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(@mock_inner, 'structMetadata')
      test_obj.ng_xml.should be_equivalent_to(@rv_doc)
    end

    it "should replace existing structMetadata content from setter" do
      @mock_repo.stubs(:datastream_profile).returns({:dsID => 'structMetadata'})
      @mock_repo.stubs(:datastream_dissemination=>@rv_fixture)
  	  test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(@mock_inner, 'structMetadata')
      test_obj.ng_xml.should be_equivalent_to(@rv_doc)
      test_obj.content= @seq_fixture
      test_obj.ng_xml.should be_equivalent_to(@seq_doc)
    end
  end

  describe ".serialize! " do
    it "should signal changes to ng_xml" do
      @mock_repo.stubs(:datastream_profile).returns({:dsID => 'structMetadata'})
      @mock_repo.stubs(:datastream_dissemination=>@rv_fixture)
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(@mock_inner, 'structMetadata')
      expected = Nokogiri::XML::Document.parse(@rv_fixture.sub(/Sides/,'sediS'))
      test_obj.label = 'sediS'
      test_obj.serialize!
      test_obj.changed?.should be_true
      Nokogiri::XML::Document.parse(test_obj.content).should be_equivalent_to(expected)
    end
  end

  describe "Recto/Verso convenince methods" do
    it "should act otherwise identically to building with .create_div_node" do
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(nil, 'structMetadata', label:'Sides', type:'physical')
      test_obj.recto_verso!
      test_obj.recto['CONTENTIDS']="rbml_css_0702r"
      test_obj.verso['CONTENTIDS']="rbml_css_0702v"
      test_obj.ng_xml.should be_equivalent_to(@rv_doc)
      test_obj.changed?.should be_true
    end

    it "should not change content unnecessarily" do
      @mock_repo.stubs(:datastream_profile).returns({:dsID => 'structMetadata'})
      @mock_repo.stubs(:datastream_dissemination=>@rv_fixture)
      test_obj = Cul::Scv::Hydra::ActiveFedora::Model::StructMetadata.new(@mock_inner, 'structMetadata')
      test_obj.changed?.should be_false
      test_obj.recto_verso!
      test_obj.changed?.should be_false
    end
  end
end
