require 'base64'

module ArtifactDeck::Encode
  INVALID_DECK = 'Invalid deck'.freeze

  def self.call(deck = {})
    raise INVALID_DECK if deck.empty? || !deck[:heroes] || !deck[:cards]

    heroes = deck[:heroes].sort { |x, y| x[:id] <=> y[:id] }
    cards = deck[:cards].sort { |x, y| x[:id] <=> y[:id] }

    encoder = Encoder.new
    encoder.write_var(heroes.count, 3)
    heroes.each { |h| encoder.write_card(h[:id], h[:turn]) }
    encoder.reset_previous_id!
    cards.each { |c| encoder.write_card(c[:id], c[:count]) }

    version_and_heroes = ArtifactDeck::CURRENT_VERSION << 4 | Encoder.extract_n_bits_with_carry(heroes.count, 3)
    checksum = ArtifactDeck.computed_checksum(encoder.bytes)
    name = deck[:name][0..63]
    header = [version_and_heroes, checksum, name.length]
    name_arr = name.chars.map(&:ord)
    encoded_arr = header + encoder.bytes + name_arr
    packed_str = encoded_arr.pack('C*')
    encoded_str = Base64.strict_encode64(packed_str)
    encoded_str.gsub!('/', '-')
    encoded_str.gsub!('=', '_')
    ArtifactDeck::ENCODED_PREFIX + encoded_str
  end

  class Encoder
    attr_reader :bytes, :previous_id

    def initialize
      @bytes = []
      @previous_id = 0
    end

    def write_var(value, bits_to_skip)
      return if value < (1 << bits_to_skip)

      value = (value & 0xFFFF) >> bits_to_skip
      while value > 0 do
        @bytes << self.class.extract_n_bits_with_carry(value, 7)
        value = (value & 0xFFFF) >> 7
      end
    end

    def write_card(id, n)
      n_part = n <= 3 ? n - 1 : 3

      delta = id - previous_id
      @previous_id = id
      id_part = self.class.extract_n_bits_with_carry(delta, 5)
      @bytes << ((n_part << 6) | id_part)
      write_var(delta, 5)
      write_var(n, 0) if n > 3
    end

    def reset_previous_id!
      @previous_id = 0
    end

    def self.extract_n_bits_with_carry(value, bits)
      limit_bit = 1 << bits
      return value if value < limit_bit

      limit_bit | (value & (limit_bit - 1))
    end
  end
end
