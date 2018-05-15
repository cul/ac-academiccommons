require 'rails_helper'

describe 'rake sitemap:create', type: :task do
  let(:path) { Rails.root.join('public', 'sitemap.xml.gz') }

  before(:each) { task.execute }

  it 'generates sitemap with out errors' do
    expect(File.exist?(path)).to be true
  end

  it 'generates expected xml' do
    pending 'decision about uncompressed/compressed sitemap'
  end
end
