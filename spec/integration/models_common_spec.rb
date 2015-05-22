require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Cul::Hydra::Models::Common, type: :integration do

  before(:all) do
    # For direct member test
    @content_aggregator_with_direct_child = ContentAggregator.new(pid: 'test:c_agg_with_direct_child')
    @content_aggregator_with_direct_child.save
    
    @direct_member_generic_resource = GenericResource.new(pid: 'test:g_res_direct')
    @direct_member_generic_resource.add_relationship(:cul_member_of, @content_aggregator_with_direct_child.internal_uri)
    @direct_member_generic_resource.save
    
    # For struct test
    @content_aggregator_with_struct_children = ContentAggregator.new(pid: 'test:c_agg_with_struct_child_1')
    @content_aggregator_with_struct_children.save
    
    @struct_member_generic_resource_1 = GenericResource.new(pid: 'test:g_res_struct_1')
    @struct_member_generic_resource_1.save
    @struct_member_generic_resource_2 = GenericResource.new(pid: 'test:g_res_struct_2')
    @struct_member_generic_resource_2.save
    
    struct_ds = Cul::Hydra::Datastreams::StructMetadata.new(nil, 'structMetadata', label:'Sequence', type:'logical')
    struct_ds.create_div_node(nil, {order: 2, label: "Item 2", contentids: @struct_member_generic_resource_2.pid})
    struct_ds.create_div_node(nil, {order: 1, label: "Item 1", contentids: @struct_member_generic_resource_1.pid})
    @content_aggregator_with_struct_children.datastreams['structMetadata'].ng_xml = struct_ds.ng_xml
  end

  after(:all) do
    @content_aggregator_with_direct_child.delete
    @direct_member_generic_resource.delete
    @content_aggregator_with_struct_children.delete
    @struct_member_generic_resource_1.delete
    @struct_member_generic_resource_2.delete
  end
  
  describe ".get_representative_generic_resource" do
    it "should return the generic resource object that it's invoked on" do
      expect(@direct_member_generic_resource.get_representative_generic_resource).to eq(@direct_member_generic_resource)
    end
    
    it "should return the :cul_member_of child of the given content_aggregator when no struct map is present" do
      # Need to wait because the resource index takes time to update (because immediate updates aren't enabled by default).  Wait for maximum of 10 seconds.
      10.times {
        break if @content_aggregator_with_direct_child.get_representative_generic_resource != nil
        puts 'Waiting for ResourceIndex to update...'
        sleep 1
      }
      expect(@content_aggregator_with_direct_child.get_representative_generic_resource).to eq(@direct_member_generic_resource)
    end
    
    it "should return the first structmap member" do
      expect(@content_aggregator_with_struct_children.get_representative_generic_resource).to eq(@struct_member_generic_resource_1)
    end
    
    
    
  end
  
  describe ".to_solr" do
    it "should include representative_generic_resource_pid_ssi" do
      expect(@direct_member_generic_resource.to_solr['representative_generic_resource_pid_ssi']).to eq('test:g_res_direct')
      expect(@content_aggregator_with_direct_child.to_solr['representative_generic_resource_pid_ssi']).to eq('test:g_res_direct')
      expect(@content_aggregator_with_struct_children.to_solr['representative_generic_resource_pid_ssi']).to eq('test:g_res_struct_1')
    end
  end

end
