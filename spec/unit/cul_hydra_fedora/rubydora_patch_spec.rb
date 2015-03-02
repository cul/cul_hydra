require File.expand_path(File.join(File.dirname(__FILE__),'..','..','spec_helper'))

describe Cul::Hydra::Fedora::RubydoraPatch, type: :unit do

  before do
    class TestRubydoraPatch
      include Cul::Hydra::Fedora::RubydoraPatch
    end
  end
  after do
    Object.send :remove_const, :TestRubydoraPatch
  end
  subject { TestRubydoraPatch.new }
  it "should call #risearch with itql params" do
    expect(subject).to receive(:risearch).with('foo',{lang: 'itql'})
    subject.find_by_itql 'foo'
  end
end