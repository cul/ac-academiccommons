# frozen_string_literal: true

require 'rails_helper'

describe SiteOption, type: :model do
  subject { described_class.new(name: option, value: false) }

  let(:option) { 'test_option' }

  before do
    stub_const('SiteOption::OPTIONS', [option])
  end

  describe '.default_value_for_option' do
    it 'returns false if the option key exists' do
      expect(described_class.default_value_for_option(option)).to be(false)
    end

    it 'throws an ArgumentError error if the option does not exist' do
      expect { described_class.default_value_for_option('not_an_option') }.to raise_error(ArgumentError)
    end
  end
end
