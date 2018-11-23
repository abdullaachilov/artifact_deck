require 'artifact_deck/version'
require 'artifact_deck/encode'
require 'artifact_deck/decode'

module ArtifactDeck
  ENCODED_PREFIX = 'ADC'.freeze
  UNPACK_FORMAT = 'C*'.freeze
  FIRST_VERSION = 1
  CURRENT_VERSION = 2

  def self.encode(deck = {})
    Encode.call(deck)
  end

  def self.decode(string = '')
    Decode.call(string)
  end

  def self.computed_checksum(bytes = [])
    bytes.inject(0, :+) & 0xFF
  end
end
