require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Cul::Hydra::Datastreams::StructMetadata", type: :unit do

  before(:all) do

  end

  before(:each) do
    @mock_inner = double('inner object')
    @mock_inner.stub(:"new_record?").and_return(false)
    @mock_repo = double('repository')
    @mock_ds = double('datastream')
    @mock_repo.stub(:config).and_return({})
    @mock_repo.stub(:datastream_profile).and_return({})
    #@mock_repo.stubs(:datastream_dissemination=>'My Content')
    @mock_inner.stub(:repository).and_return(@mock_repo)
    @mock_inner.stub(:pid)
    @rv_fixture = fixture( File.join("STRUCTMAP", "structmap-recto.xml")).read
    @rv_doc = Nokogiri::XML::Document.parse(@rv_fixture)
    @struct_fixture = structMetadata(@mock_inner, @rv_fixture)
    @seq_fixture = fixture( File.join("STRUCTMAP", "structmap-seq.xml")).read
    @seq_doc = Nokogiri::XML::Document.parse(@seq_fixture)
    @unlabeled_seq_fixture = fixture( File.join("STRUCTMAP", "structmap-unlabeled-seq.xml")).read
    @unordered_seq_fixture = fixture( File.join("STRUCTMAP", "structmap-unordered-seq.xml")).read
    @nested_seq_fixture = fixture( File.join("STRUCTMAP", "structmap-nested.xml")).read
  end

  describe ".new " do
    it "should create a new DS when no structMetadata exists" do
      @mock_repo.stub(:datastream_profile).and_return({})
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(@mock_inner, 'structMetadata')
      # it should have the default content
      test_obj.ng_xml.should be_equivalent_to Cul::Hydra::Datastreams::StructMetadata.xml_template
      # but it shouldn't be "saveable" until you do something
      expect(test_obj.new?).to be_truthy
      expect(test_obj.changed?).to be_falsey
      # like assigning an attribute value
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(@mock_inner,
       'structMetadata', :label=>'TEST LABEL')
      expect(test_obj.new?).to be_truthy
      expect(test_obj.changed?).to be_truthy
    end
  end

  describe ".create_div_node " do
	  it "should build a simple R/V structure" do
	  	built = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sides', type:'physical')
	  	built.create_div_node(nil, {:order=>"1", :label=>"Recto", :contentids=>"rbml_css_0702r"})
	  	built.create_div_node(nil, {:order=>"2", :label=>"Verso", :contentids=>"rbml_css_0702v"})
	  	expect(built.ng_xml).to be_equivalent_to(@rv_doc)
	  end

    it "should build a simple sequence structure" do
      built = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sequence', type:'logical')
      built.create_div_node(nil, {:order=>"1", :label=>"Item 1", :contentids=>"prd.custord.060108.001"})
      built.create_div_node(nil, {:order=>"2", :label=>"Item 2", :contentids=>"prd.custord.060108.002"})
      built.create_div_node(nil, {:order=>"3", :label=>"Item 3", :contentids=>"prd.custord.060108.003"})
      built.ng_xml.should be_equivalent_to(@seq_doc)
    end

    it "should work if the parent node has its own NS prefix" do
      test_src = "<foo:structMap xmlns:foo=\"http://www.loc.gov/METS/\" />"
      test_obj = Cul::Hydra::Datastreams::StructMetadata.from_xml test_src
      test_div = test_obj.create_div_node
      test_div.namespace.prefix.should == "foo"
    end

    it "should work if the parent node is in the default NS" do
      test_src = "<structMap xmlns=\"http://www.loc.gov/METS/\" />"
      test_obj = Cul::Hydra::Datastreams::StructMetadata.from_xml test_src
      test_div = test_obj.create_div_node
      test_div.namespace.prefix.should be_nil
    end
  end

  describe ".content= " do
    it "should parse existing structMetadata content appropriately" do
      @mock_repo.stub(:datastream_profile).and_return({:dsID => 'structMetadata'})
      @mock_repo.stub(:datastream_dissemination=>@rv_fixture)
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(@mock_inner, 'structMetadata')
      test_obj.ng_xml.should be_equivalent_to(@rv_doc)
    end

    it "should replace existing structMetadata content from setter" do
      @mock_repo.stub(:datastream_profile).and_return({:dsID => 'structMetadata'})
      @mock_repo.stub(:datastream_dissemination=>@rv_fixture)
  	  test_obj = Cul::Hydra::Datastreams::StructMetadata.new(@mock_inner, 'structMetadata')
      test_obj.ng_xml.should be_equivalent_to(@rv_doc)
      test_obj.content= @seq_fixture
      test_obj.ng_xml.should be_equivalent_to(@seq_doc)
    end
  end

  describe ".serialize! " do
    it "should signal changes to ng_xml" do
      @mock_repo.stub(:datastream_profile).and_return({:dsID => 'structMetadata'})
      @mock_repo.stub(:datastream_dissemination=>@rv_fixture)
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(@mock_inner, 'structMetadata')
      expected = Nokogiri::XML::Document.parse(@rv_fixture.sub(/Sides/,'sediS'))
      test_obj.label = 'sediS'
      test_obj.serialize!
      test_obj.changed?.should be_truthy
      Nokogiri::XML::Document.parse(test_obj.content).should be_equivalent_to(expected)
    end
  end

  describe "Recto/Verso convenince methods" do
    it "should act otherwise identically to building with .create_div_node" do
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sides', type:'physical')
      test_obj.recto_verso!
      test_obj.recto['CONTENTIDS']="rbml_css_0702r"
      test_obj.verso['CONTENTIDS']="rbml_css_0702v"
      test_obj.ng_xml.should be_equivalent_to(@rv_doc)
      test_obj.changed?.should be_truthy
    end

    it "should not change content unnecessarily" do
      @mock_repo.stub(:datastream_profile).and_return({:dsID => 'structMetadata'})
      @mock_repo.stub(:datastream_dissemination=>@rv_fixture)
      test_obj = Cul::Hydra::Datastreams::StructMetadata.new(@mock_inner, 'structMetadata')
      test_obj.changed?.should be_falsey
      test_obj.recto_verso!
      test_obj.changed?.should be_falsey
    end
  end

  describe "Retrieving data from a structmap" do
		it "should be able to retrieve divs with a CONTENTIDS attribute" do
			struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(@seq_fixture)
			divs_with_contentids_attr = struct.divs_with_attribute(true, 'CONTENTIDS')
			divs_with_contentids_attr.length.should == 3
		end
		it "should be able to retrieve the first ordered content div (where ORDER=\"1\"), regardless of div order" do
			struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(@unordered_seq_fixture)
			divs_with_contentids_attr = struct.first_ordered_content_div
			divs_with_contentids_attr.attr('ORDER').should == '1'
			divs_with_contentids_attr.attr('LABEL').should == 'Item 1'
			divs_with_contentids_attr.attr('CONTENTIDS').should == 'prd.custord.060108.001'
		end
	end
  describe "Proxies" do
    before do
      @digital_object = double('Digital Object')
      allow(@digital_object).to receive(:pid).and_return('test:0000')
    end
    context "for recto/verso" do
      subject {
        struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(@rv_fixture)
        struct.instance_variable_set(:@digital_object, @digital_object)
        struct.proxies
      }
      it { expect(subject.length).to eql 2 }
      describe "index as" do
        let(:solr_docs) { subject.collect{|x| x.to_solr } }
        it "should be generate solr hashes for all the structure proxies" do
          missing = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(missing).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','2']
        end
      end
    end
    context "for a flat list" do
      subject {
        struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(@unordered_seq_fixture)
        struct.instance_variable_set(:@digital_object, @digital_object)
        struct.proxies
      }
      it { expect(subject.length).to eql 3 }
      describe "index as" do
        let(:solr_docs) { subject.collect{|x| x.to_solr } }
        it "should be generate solr hashes for all the structure proxies" do
          missing = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(missing).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','2','3']
        end
      end
    end
    context "for a flat list without labels" do
      subject {
        struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(@unlabeled_seq_fixture)
        struct.instance_variable_set(:@digital_object, @digital_object)
        struct.proxies
      }
      it { expect(subject.length).to eql 2 }
      describe "index as" do
        let(:solr_docs) { subject.collect{|x| x.to_solr } }
        it "should generate solr_docs with ids" do
          solr_docs.each {|solr_doc| expect(solr_doc['id']).not_to be_nil}
        end
        it "should be generate solr hashes for all the structure proxies" do
          missing = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(missing).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','2']
        end
      end
    end
    context "for a nested structure" do
      subject {
        struct = Cul::Hydra::Datastreams::StructMetadata.from_xml(@nested_seq_fixture)
        struct.instance_variable_set(:@digital_object, @digital_object)
        struct.instance_variable_set(:@dsid, 'structDS')
        struct.proxies
      }
      it { expect(subject.length).to eql 6 }
      describe "index as" do
        let(:solr_docs) { subject.collect{|x| x.to_solr } }
        it "should generate solr hashes for all the structure proxies with label, proxyIn and proxyFor" do
          docs = solr_docs.detect {|x| x['proxyIn_ssi'] != 'info:fedora/test:0000'}
          expect(docs).to be_nil
          docs = solr_docs.detect {|x| !x['proxyFor_ssi']}
          expect(docs).to be_nil
          docs = solr_docs.detect {|x| !x['label_ssi']}
          expect(docs).to be_nil
        end
        it "should identify the proxy index with index" do
          docs = solr_docs.sort {|a,b| a['index_ssi'] <=> b['index_ssi']}
          index_values = docs.collect {|x| x['index_ssi']}
          expect(index_values).to eql ['1','1','1','2','2','2']
        end
        it "should create nfo:file proxies for resources" do
          folders = solr_docs.select {|d| d['type_ssim'].include? RDF::NFO[:"#Folder"].to_s}
          files = solr_docs.select {|d| d['type_ssim'].include? RDF::NFO[:"#FileDataObject"].to_s}
          expect(folders.length).to eql 2
          expect(files.length).to eql 4
        end
        it "should set belongsToContainer appropriately" do
          aggs = {}
          solr_docs.each {|d| a = (aggs[d['belongsToContainer_ssi']] ||= []); a << d['id'] }
          expect(aggs.size).to eql 3
          leaf1 = "info:fedora/test:0000/structDS/Leaf1"
          leaf2 = "info:fedora/test:0000/structDS/Leaf2"
          expect(aggs).to include leaf1
          expect(aggs[leaf1.to_s].length).to eql 2
          expect(aggs).to include leaf2
          expect(aggs[leaf2.to_s].length).to eql 2
          expect(aggs[nil].sort).to eql [leaf1, leaf2] # sort order of IDs
          expect(aggs[leaf1].sort).to eql ["#{leaf1}/Recto", "#{leaf1}/Verso"] # sort order of IDs
          expect(aggs[leaf2].sort).to eql ["#{leaf2}/Recto", "#{leaf2}/Verso"] # sort order of IDs
        end
        it "should set isPartOf for all the ancestor segments" do
          proxy = solr_docs.detect{ |d| d['id'].eql? "info:fedora/test:0000/structDS/Leaf1/Verso"}
          expect(proxy['isPartOf_ssim']).to eql ["info:fedora/test:0000/structDS/Leaf1"]
        end
      end
    end
    context "when composing from several sources" do
      let(:source1) do
        src = fixture( File.join("STRUCTMAP", "structmap-nested.xml")).read
        Cul::Hydra::Datastreams::StructMetadata.from_xml(src)
      end
      let(:source2) do
        src = fixture( File.join("STRUCTMAP", "structmap-nested2.xml")).read
        Cul::Hydra::Datastreams::StructMetadata.from_xml(src)
      end
      let(:combined) do
        Nokogiri::XML(fixture( File.join("STRUCTMAP", "structmap-nested3.xml")).read)
      end
      subject do
        ds = Cul::Hydra::Datastreams::StructMetadata.new
        ds.merge(source1, source2)
      end
      it "should be equivalent to the composite source" do
        expect(subject.ng_xml).to be_equivalent_to(combined)
        expect(subject.changed?).to be
      end
    end
  end
end
