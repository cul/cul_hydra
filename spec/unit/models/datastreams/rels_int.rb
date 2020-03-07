require 'spec_helper'

describe Cul::Hydra::Datastreams::RelsInt , type: :unit do
  let(:pid) { "test:relsint" }
  let(:inner) do
    inner = double("DigitalObject")
    allow(inner).to receive(:pid).and_return(pid)
    allow(inner).to receive(:internal_uri).and_return("info:fedora/test:relsint")
    allow(inner).to receive(:repository).and_return(repo)
    inner
  end
  let(:repo) do
    repo = double("Repository")
    allow(repo).to receive(:datastream_dissemination).with(:pid=>pid,:dsid=>"RELS-INT").and_return(test_relsint)
    repo
  end
  let(:test_relsint) { fixture(File.join('CUL_RELS_INT', 'rels_int_test.xml')).read }
  let(:profile) do
    profile_xml = fixture(File.join('CUL_RELS_INT', 'rels_int_profile.xml')).read
    profile = Rubydora::ProfileParser.parse_datastream_profile(profile_xml)
    profile
  end
  let(:datastream) do
    described_class.new(inner,"RELS-INT")
  end
  before do
    allow(inner).to receive(:new_record?).and_return(false)
    allow(repo).to receive(:datastream_profile).with(pid,"RELS-INT",nil, nil).and_return(profile)
  end
  context "on a new object" do
    before do
      allow(inner).to receive(:new_record?).and_return(true)
    end
    it "should serialize to appropriate RDF-XML" do
      blank_relsint = fixture(File.join('CUL_RELS_INT', 'rels_int_blank.xml')).read
      expect(Nokogiri::XML.parse(datastream.content)).to be_equivalent_to Nokogiri::XML.parse(blank_relsint)
    end
  end
  context "is a new datastream on an existing object" do
    before do
      # new datastream, no profile
      allow(repo).to receive(:datastream_profile).with(pid,"RELS-INT",nil, nil).and_return('')
    end
    it "should serialize to appropriate RDF-XML" do
      blank_relsint = fixture(File.join('CUL_RELS_INT', 'rels_int_blank.xml')).read
      expect(Nokogiri::XML.parse(datastream.content)).to be_equivalent_to Nokogiri::XML.parse(blank_relsint)
    end
  end

  it "should load relationships from foxml into the appropriate graphs" do
    expect(datastream.changed?).to be(false)
    dc = ActiveFedora::Datastream.new(inner,"DC")
    triples = datastream.relationships(dc,:is_metadata_for)
    e = ['info:fedora/test:relsint/DC','info:fedora/fedora-system:def/relations-external#isMetadataFor','info:fedora/test:relsint/RELS-INT'].
      map {|x| RDF::URI.new(x)}
    f = ['info:fedora/test:relsint/DC','info:fedora/fedora-system:def/relations-external#isMetadataFor','info:fedora/test:relsint/RELS-EXT']
      .map {|x| RDF::URI.new(x)}
    expect(triples).to eq([RDF::Statement.new(*e),RDF::Statement.new(*f)])
    expect(Nokogiri::XML.parse(datastream.content)).to be_equivalent_to Nokogiri::XML.parse(test_relsint)
  end
  it "should load relationships into appropriate graphs when assigned content" do
    datastream.content=test_relsint
    expect(datastream.changed?).to be(true)
    dc = ActiveFedora::Datastream.new(inner,"DC")
    triples = datastream.relationships(dc,:is_metadata_for)
    e = ['info:fedora/test:relsint/DC','info:fedora/fedora-system:def/relations-external#isMetadataFor','info:fedora/test:relsint/RELS-INT']
      .map {|x| RDF::URI.new(x)}
    f = ['info:fedora/test:relsint/DC','info:fedora/fedora-system:def/relations-external#isMetadataFor','info:fedora/test:relsint/RELS-EXT']
      .map {|x| RDF::URI.new(x)}
    expect(triples).to eq([RDF::Statement.new(*e),RDF::Statement.new(*f)])
  end
  it "should propagate relationship changes to the appropriate graph in RELS-INT" do
    dc = ActiveFedora::Datastream.new(inner,"DC")
    rels_ext = ActiveFedora::Datastream.new(inner,"RELS-EXT")
    expect(datastream.to_resource(datastream)).to eql(RDF::URI.new("info:fedora/#{inner.pid}/#{datastream.dsid}"))
    datastream.add_relationship(dc,:is_metadata_for, datastream)
    datastream.add_relationship(dc,:is_metadata_for, rels_ext)
    datastream.add_relationship(rels_ext,:asserts, "FOO", true)
    datastream.add_relationship(datastream,:asserts, "BAR", true)
    datastream.serialize!
    expect(Nokogiri::XML.parse(datastream.content)).to be_equivalent_to Nokogiri::XML.parse(test_relsint)
  end
  it "should clear matching relationships selectively" do
    datastream.content=test_relsint
    rels_ext = ActiveFedora::Datastream.new(inner,"RELS-EXT")
    test_pred = 'http://projecthydra.org/ns/relations#asserts'
    expect(datastream.relationships(rels_ext,:asserts)).to_not be_empty
    datastream.clear_relationship('info:fedora/test:relsint/RELS-EXT',:asserts)
    expect(datastream.relationships(rels_ext,:asserts)).to be_empty
    expect(datastream.relationships(datastream,:asserts)).to_not be_empty
  end
  it "should run to_solr" do
    datastream.content=test_relsint
    expect(datastream.changed?).to be(true)
    expect{datastream.to_solr}.to_not raise_error
  end
  describe "#to_resource" do
    # FCRepo 3.x only supports RDF::XSD.int, RDF::XSD.long, RDF::XSD.float, RDF::XSD.double,
    # and RDF::XSD.date_time but RDF uses RDF::XSD.integer, RDF::XSD.boolean
    {
      0 => RDF::XSD.int, 32767 => RDF::XSD.int, -32768 => RDF::XSD.int,
      2147483647 => RDF::XSD.int, -2147483648 => RDF::XSD.int,
      2147483648 => RDF::XSD.long, -2147483649 => RDF::XSD.long,
      true => nil, false => nil,
      BigDecimal('2.5') => RDF::XSD.double, 2.5.to_f => RDF::XSD.double,
      Time.new => RDF::XSD.date_time, Date.new => RDF::XSD.date_time, DateTime.new => RDF::XSD.date_time
    }.each do |value, datatype|
      it "should assign implicit datatypes to #{value.class.name} literals such as #{value} valid for FCRepo 3" do
        expect(datastream.to_resource(value,true).datatype).to eql(datatype)
      end
    end
  end
end
