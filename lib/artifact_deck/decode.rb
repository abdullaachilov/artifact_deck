require 'base64'

module ArtifactDeck::Decode
  INVALID_PREFIX = 'Invalid deck code prefix'.freeze
  INVALID_VERSION = 'This version is not supported'.freeze
  INVALID_CHECKSUM = 'Invalid checksum'.freeze
  INVALID_DECK_CODE = 'Invalid deck code'.freeze

  def self.call(string)
    bytes = decode_string(string)
    parse_deck(bytes)
  end


  def self.decode_string(str)
    raise INVALID_PREFIX unless str.start_with?(ArtifactDeck::ENCODED_PREFIX)

    str.slice!(0, ArtifactDeck::ENCODED_PREFIX.length)
    str.gsub!('-', '/')
    str.gsub!('_', '=')
    decoded = Base64.decode64(str)
    decoded.unpack(ArtifactDeck::UNPACK_FORMAT)
  end

  def self.parse_deck(bytes)
    bytes_count = bytes.length
    version_and_heroes = bytes[0]
    version = (version_and_heroes >> 4)

    raise INVALID_VERSION if version != ArtifactDeck::CURRENT_VERSION && version != ArtifactDeck::FIRST_VERSION

    checksum = bytes[1]

    byte_index = 2
    str_length = 0
    if version > 1
      str_length = bytes[byte_index]
      byte_index += 1
    end
    card_bytes_count = bytes_count - str_length

    computed_checksum = 0
    deck_bytes = bytes[byte_index...card_bytes_count]

    masked = ArtifactDeck.computed_checksum(deck_bytes)

    raise INVALID_CHECKSUM if masked != checksum

    heroes = []

    decoder = Decoder.new(deck_bytes)
    heroes_length = decoder.read_var(version_and_heroes, 3)

    heroes_length.times do |i|
      heroes << decoder.read_card(name: :turn)
    end

    decoder.reset_previous_id!
    cards = []
    loop do
      cards << decoder.read_card(name: :count)
      break unless decoder.has_next?
    end

    name = bytes[card_bytes_count..bytes.length].map{ |i| i.chr(Encoding::UTF_8) }.join

    { heroes: heroes, cards: cards, name: name }
  end



  class Decoder
    attr_reader :bytes, :bytes_length, :index, :previous_id

    def initialize(bytes)
      @bytes = bytes
      @bytes_length = bytes.count
      @index = 0
      @previous_id = 0
    end

    def read_var(base_value, base_bits)
      result = 0

      if base_bits != 0
        continue_bit = (1 << base_bits)
        result = base_value & (continue_bit - 1)
        return result if (base_value & continue_bit) == 0
      end

      current_shift = base_bits

      loop do
        raise Decode::INVALID_DECK_CODE if index >= bytes_length

        current_byte = bytes[index]
        @index = index + 1
        result |= ((current_byte & 127) << current_shift)
        current_shift += 7

        break if (current_byte & 128) <= 0
      end
      result
    end

    def read_card(name: )
      raise Decode::INVALID_DECK_CODE if index >= bytes_length

      header = bytes[index]
      @index = index + 1
      id = previous_id + read_var(header, 5)
      @previous_id = id
      count = (header >> 6)
      count = count == 3 ? readVar(0, 0) : (count + 1)
      { id: id, name => count }
    end

    def has_next?
      index < bytes_length
    end

    def reset_previous_id!
      @previous_id = 0
    end
  end
end
