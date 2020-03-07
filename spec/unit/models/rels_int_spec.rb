require 'spec_helper'

describe Cul::Hydra::Models::RelsInt, type: :unit do
  it do
    is_expected.to be
    expect(defined? Cul::Hydra::Datastreams::RelsInt).to be
  end
  context "is included in a subclass of ActiveFedora::Base" do
    let(:af_model) do
      af_model = Class.new(ActiveFedora::Base)
      af_model.class_eval do
        include Cul::Hydra::Models::RelsInt
      end
      af_model
    end
    it "should add the appropriate ds_spec and accessor methods when mixed in" do
      expect(af_model.ds_specs.keys).to include( 'RELS-INT')
      expect(af_model.ds_specs['RELS-INT'][:type]).to be(Cul::Hydra::Datastreams::RelsInt)
    end
  end
end
