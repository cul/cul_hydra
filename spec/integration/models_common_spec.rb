require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cul::Hydra::Models::Common, type: :integration do

  before(:all) do
    # For direct member test
    @content_aggregator_with_direct_child = ContentAggregator.new(pid: 'test:c_agg_with_direct_child')
    @content_aggregator_with_direct_child.save
    
    @direct_member_generic_resource = GenericResource.new(pid: 'test:g_res_direct')
    @direct_member_generic_resource.add_relationship(:cul_member_of, @content_aggregator_with_direct_child.internal_uri)
    @direct_member_generic_resource.save
    
    # For struct test with PID in structMap, but not in dc:identifier
    @content_aggregator_with_struct_children_1 = ContentAggregator.new(pid: 'test:c_agg_with_struct_child_1')
    @content_aggregator_with_struct_children_1.save
    
    @struct_member_generic_resource_1 = GenericResource.new(pid: 'test:g_res_struct_1')
    @struct_member_generic_resource_1.save
    @struct_member_generic_resource_2 = GenericResource.new(pid: 'test:g_res_struct_2')
    @struct_member_generic_resource_2.save
    
    struct_ds = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sequence', type:'logical')
    struct_ds.create_div_node(nil, {order: 2, label: "Item 2", contentids: 'test:g_res_struct_2'})
    struct_ds.create_div_node(nil, {order: 1, label: "Item 1", contentids: 'test:g_res_struct_1'})
    @content_aggregator_with_struct_children_1.datastreams['structMetadata'].ng_xml = struct_ds.ng_xml
    @content_aggregator_with_struct_children_1.save
    
    # For struct test with dc:identifier in structMap
    @content_aggregator_with_struct_children_a = ContentAggregator.new(pid: 'test:c_agg_with_struct_child_a')
    @content_aggregator_with_struct_children_a.save
    
    @struct_member_generic_resource_a = GenericResource.new(pid: 'test:g_res_struct_a')
    @struct_member_generic_resource_a.save
    @struct_member_generic_resource_a.datastreams["DC"].dc_identifier = 'apt://some/uri-like/identifier/for/g_res_struct_a'
    @struct_member_generic_resource_a.save
    
    @struct_member_generic_resource_b = GenericResource.new(pid: 'test:g_res_struct_b')
    @struct_member_generic_resource_b.save
    @struct_member_generic_resource_b.datastreams["DC"].dc_identifier = 'identifier_for_test:g_res_struct_b'
    @struct_member_generic_resource_b.save
    
    struct_ds = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sequence', type:'logical')
    struct_ds.create_div_node(nil, {order: 2, label: "Item 2", contentids: 'identifier_for_test:g_res_struct_b'})
    struct_ds.create_div_node(nil, {order: 1, label: "Item 1", contentids: 'apt://some/uri-like/identifier/for/g_res_struct_a'})
    @content_aggregator_with_struct_children_a.datastreams['structMetadata'].ng_xml = struct_ds.ng_xml
    @content_aggregator_with_struct_children_a.save
    
  end

  after(:all) do
    @content_aggregator_with_direct_child.delete
    @direct_member_generic_resource.delete
    @content_aggregator_with_struct_children_1.delete
    @content_aggregator_with_struct_children_a.delete
    @struct_member_generic_resource_1.delete
    @struct_member_generic_resource_2.delete
    @struct_member_generic_resource_a.delete
    @struct_member_generic_resource_b.delete
  end
  
  describe ".get_representative_generic_resource" do
    it "should return the generic resource object that it's invoked on" do
      expect(@direct_member_generic_resource.get_representative_generic_resource).to eq(@direct_member_generic_resource)
    end
    
    it "should return the :cul_member_of child of the given content_aggregator when no struct map is present" do
      representative_generic_resource = @content_aggregator_with_direct_child.get_representative_generic_resource
      expect(representative_generic_resource).to eq(@direct_member_generic_resource)
      expect(representative_generic_resource).to be_kind_of(GenericResource)
    end
    
    it "should return the first structmap member when a PID is present in the structMap rather than a dc:identifier" do
      representative_generic_resource = @content_aggregator_with_struct_children_1.get_representative_generic_resource
      expect(representative_generic_resource).to eq(@struct_member_generic_resource_1)
      expect(representative_generic_resource).to be_kind_of(GenericResource)
    end
    
    it "should return the first structmap member when a dc:identifier is present in the structMap rather than PID (and that dc:identifier can be a uri that would not be a valid fedora identifier)" do
      representative_generic_resource = @content_aggregator_with_struct_children_a.get_representative_generic_resource(true)
      expect(representative_generic_resource).to eq(@struct_member_generic_resource_a)
      expect(representative_generic_resource).to be_kind_of(GenericResource)
    end
  end
  
  describe ".to_solr" do
    it "should include representative_generic_resource_pid_ssi" do
      expect(@direct_member_generic_resource.to_solr['representative_generic_resource_pid_ssi']).to eq('test:g_res_direct')
      expect(@content_aggregator_with_direct_child.to_solr['representative_generic_resource_pid_ssi']).to eq('test:g_res_direct')
      expect(@content_aggregator_with_struct_children_1.to_solr['representative_generic_resource_pid_ssi']).to eq('test:g_res_struct_1')
      expect(@content_aggregator_with_struct_children_a.to_solr['representative_generic_resource_pid_ssi']).to eq('test:g_res_struct_a')
    end
  end

end
