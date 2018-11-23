RSpec.describe ArtifactDeck do
  V2_STRING = 'ADCJWkTZX05uwGDCRV4XQGy3QGLmqUBg4GQJgGLGgO7AaABR3JlZW4vQmxhY2sgRXhhbXBsZQ__'
  V1_STRING = 'ADCFWllfTm7AYMJFXhdAbLdAYuapQGDgZAmAYsaA7sBoAE_'
  INVALID_V2_STRING = 'ADJWkTZX05uwGDCRV4XQGy3QGLmqUBg4GQJgGLGgO7AaABR3JlZW4vQmxhY2sgRXhhbXBsZQ__'

  # fixtures :decks

  it "has a version number" do
    expect(ArtifactDeck::VERSION).not_to be nil
  end


  context 'when input data is valid' do

    let(:deck) { json_fixture_file('deck.json') }

    it 'encodes hash' do
      expect(ArtifactDeck.encode(deck)).to eq(V2_STRING)
    end

    it 'encodes randomly ordered hash' do
      hash = { cards: deck[:cards].shuffle, heroes: deck[:heroes].shuffle, name: deck[:name] }
      expect(ArtifactDeck.encode(hash)).to eq(V2_STRING)
    end

    it 'encodes hash with random key types' do
      hash = { 'cards' => deck[:cards], heroes: deck[:heroes], 'name' => deck[:name] }
      expect(ArtifactDeck.encode(hash)).to eq(V2_STRING)
    end

    it 'decodes valid base64 v1 string' do
      result = ArtifactDeck.decode(V1_STRING)
      expect(result[:name]).to eq('')
      expect(result[:heroes]).to eq(deck[:heroes])
      expect(result[:cards]).to eq(deck[:cards])
    end

    it 'decodes valid base64 v2 string' do
      result = ArtifactDeck.decode(V2_STRING)
      expect(result[:name]).to eq(deck[:name])
      expect(result[:heroes]).to eq(deck[:heroes])
      expect(result[:cards]).to eq(deck[:cards])
    end
  end

  context 'when input data is not valid' do

    let(:deck) { json_fixture_file('deck.json') }

    it 'raises an exception when base64 string is not valid' do
      expect { ArtifactDeck.decode(INVALID_V2_STRING) }.to raise_error(StandardError, ArtifactDeck::Decode::INVALID_PREFIX)
    end

    it 'raises an exception when deck hash is not valid' do
      invalid_deck = { name: 'Some name', 'heroes' => deck[:heroes] }
      expect { ArtifactDeck.encode(invalid_deck) }.to raise_error(StandardError, ArtifactDeck::Encode::INVALID_DECK)
    end

    # TODO add more specs with invalid data
  end
end
