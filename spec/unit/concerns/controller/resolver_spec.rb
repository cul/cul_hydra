require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')

describe Cul::Hydra::Resolver, type: :unit do
  
  before do
    class TestRig
      attr_reader :params

      def self.rescue_from(*args)
      end
      
      include Cul::Hydra::Resolver

      def initialize(id, params={})
        @document = {id: id}
        @params = params
      end

      def get_solr_response_for_app_id
        # this is a no-op stub
      end
    end

  end
  after do
    Object.send :remove_const, :TestRig
  end
  subject { TestRig.new('lol:wut') }
  it "should resolve resourceful actions correctly" do
    subject.params[:action] = 'widgets'
    expect(subject).to receive(:widget_url).and_return('get:lol:wut')
    expect(subject).to receive(:redirect_to)
    subject.get
  end
  it "should resolve resourceful actions correctly" do
    subject.params[:action] = 'spaceship'
    expect(subject).to receive(:spaceship_url).and_return('get:lol:wut')
    expect(subject).to receive(:redirect_to)
    subject.get
  end
end
