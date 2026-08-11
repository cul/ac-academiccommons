# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IdSanitizable do
  let(:mock_controller) do
    Class.new do
      include IdSanitizable
      attr_accessor :params

      def initialize(params = {})
        @params = params
      end
    end
  end

  describe '.sanitize_id' do
    it 'returns the string unchanged when it contains no hidden characters' do
      expect(described_class.sanitize_id('ac:12345')).to eq('ac:12345')
    end

    it 'strips a zero width space (ZWSP)' do
      expect(described_class.sanitize_id("ac:123\u200B45")).to eq('ac:12345')
    end

    it 'strips a zero width non-joiner (ZWNJ)' do
      expect(described_class.sanitize_id("ac:123\u200C45")).to eq('ac:12345')
    end

    it 'strips a zero width joiner (ZWJ)' do
      expect(described_class.sanitize_id("ac:123\u200D45")).to eq('ac:12345')
    end

    it 'strips a non-breaking space (NBSP)' do
      expect(described_class.sanitize_id("ac:123\u00A045")).to eq('ac:12345')
    end

    it 'strips a byte order mark (BOM)' do
      expect(described_class.sanitize_id("\uFEFFac:12345")).to eq('ac:12345')
    end

    it 'strips a word joiner' do
      expect(described_class.sanitize_id("ac:123\u206045")).to eq('ac:12345')
    end

    it 'strips a soft hyphen (SHY)' do
      expect(described_class.sanitize_id("ac:123\u00AD45")).to eq('ac:12345')
    end

    it 'strips a line separator' do
      expect(described_class.sanitize_id("ac:123\u202845")).to eq('ac:12345')
    end

    it 'strips a paragraph separator' do
      expect(described_class.sanitize_id("ac:123\u202945")).to eq('ac:12345')
    end

    it 'strips multiple different hidden characters in the same string' do
      dirty = "\uFEFFac\u200B:1\u00A02\u200D345\u2028"
      expect(described_class.sanitize_id(dirty)).to eq('ac:12345')
    end

    it 'strips repeated occurrences of the same hidden character' do
      expect(described_class.sanitize_id("ac\u200B\u200B\u200B:12345")).to eq('ac:12345')
    end

    it 'returns nil for a nil input' do
      expect(described_class.sanitize_id(nil)).to be_nil
    end

    it 'returns an empty string for an empty string input' do
      expect(described_class.sanitize_id('')).to eq('')
    end
  end

  describe '#sanitize_id_param' do
    it 'replaces params[:id] with the sanitized value' do
      instance = mock_controller.new(id: "ac:123\u200B45")

      instance.sanitize_id_param

      expect(instance.params[:id]).to eq('ac:12345')
    end

    it 'leaves an already-clean id unchanged' do
      instance = mock_controller.new(id: 'ac:12345')

      instance.sanitize_id_param

      expect(instance.params[:id]).to eq('ac:12345')
    end

    it 'does nothing when there is no :id param' do
      instance = mock_controller.new(other_param: 'value')

      expect { instance.sanitize_id_param }.not_to raise_error
      expect(instance.params).to eq(other_param: 'value')
    end

    it 'does nothing when :id is nil' do
      instance = mock_controller.new(id: nil)

      instance.sanitize_id_param

      expect(instance.params[:id]).to be_nil
    end

    it 'does nothing when :id is an empty string' do
      instance = mock_controller.new(id: '')

      instance.sanitize_id_param

      expect(instance.params[:id]).to eq('')
    end

    it 'sanitizes a doi-style glob id containing hidden characters' do
      instance = mock_controller.new(id: "10.1234\u200B/some\u00A0path")

      instance.sanitize_id_param

      expect(instance.params[:id]).to eq('10.1234/somepath')
    end
  end
end
