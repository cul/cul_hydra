require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
class VocabHarness
  def self.cul
    [RDF::CUL,
      RDF::CUL::RESOURCE::STILLIMAGE::ASSESSMENT, 
      RDF::CUL::RESOURCE::STILLIMAGE::BASIC,
      RDF::CUL::FOAF]
  end
  def self.fcrepo3
    [RDF::FCREPO3::SYSTEM,
      RDF::FCREPO3::MODEL,
      RDF::FCREPO3::RELSEXT,
      RDF::FCREPO3::VIEW,
      RDF::MULGARA]
  end
  def self.nfo
    [RDF::NFO]
  end
  def self.nie
    [RDF::NIE]
  end
  def self.olo
    [RDF::OLO]
  end
  def self.ore
    [RDF::ORE]
  end
  def self.pimo
    [RDF::PIMO]
  end
end

describe "RDF Vocabularies" do
  describe RDF::CUL do
    it "should include all the CUL vocabularies" do
      VocabHarness.cul.each do |v|
        expect(v.superclass).to be RDF::StrictVocabulary
      end
    end
  end
  describe RDF::FCREPO3 do
    it "should include all the FCREPO3 vocabularies" do
      VocabHarness.fcrepo3.each do |v|
        expect(v.superclass).to be RDF::StrictVocabulary
      end
    end
  end 
  describe RDF::NFO do
    subject { RDF::NFO }
    it "should be a RDF vocabulary" do
      expect(subject.superclass).to be RDF::StrictVocabulary
    end
  end 
  describe RDF::NIE do
    subject { RDF::NIE }
    it "should be a RDF vocabulary" do
      expect(subject.superclass).to be RDF::StrictVocabulary
    end
  end 
  describe RDF::OLO do
    subject { RDF::OLO }
    it "should be a RDF vocabulary" do
      expect(subject.superclass).to be RDF::StrictVocabulary
    end
  end 
  describe RDF::ORE do
    subject { RDF::ORE }
    it "should be a RDF vocabulary" do
      expect(subject.superclass).to be RDF::StrictVocabulary
    end
  end 
  describe RDF::PIMO do
    subject { RDF::PIMO }
    it "should be a RDF vocabulary" do
      expect(subject.superclass).to be RDF::StrictVocabulary
    end
  end 
end