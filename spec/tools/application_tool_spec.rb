# frozen_string_literal: true

require 'rails_helper'

describe ApplicationTool do
  subject(:tool) { described_class.new }

  it 'instantiates' do
    expect(tool).to respond_to :query_solr
  end
end
