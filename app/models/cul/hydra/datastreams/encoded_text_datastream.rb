module Cul
module Hydra
module Datastreams
class EncodedTextDatastream < ::ActiveFedora::Datastream
  DEFAULT_PRIORITIES = [ Encoding::UTF_8, Encoding::ISO_8859_1, Encoding::WINDOWS_1252 ]
  def initialize(digital_object=nil, dsid=nil, options={})
    @encoding_priorities = options.delete(:encodings) || DEFAULT_PRIORITIES
    super
  end
  def content=(value)
    super(utf8able!(value).encode!(Encoding::UTF_8))
  end

  def content
    utf8able!(super.to_s).encode!(Encoding::UTF_8)
  end

  def utf8able!(data)
    EncodedTextDatastream.utf8able!(data, @encoding_priorities)
  end

  def self.utf8able!(data, encoding_priorities = DEFAULT_PRIORITIES)
    return unless data
    content_encoding = encoding_priorities.detect do |enc|
      begin
        data.force_encoding(enc).valid_encoding?
      rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
        false
      end
    end
    raise "could not encode text datastream content" unless content_encoding
    puts "using encoding #{content_encoding}"
    data.force_encoding(content_encoding)
  end
end
end
end
end
