namespace :load do
  task :collection => :environment do
    fedora_config = Rails.application.config_for(:fedora)
    fedora_server = ActiveFedora::Base.connection_for_pid('collection:3')
    # ingest the actest:1 aggregator
    path = 'spec/fixtures/collection_3.xml'
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.ingest(pid: 'collection:3', file: File.read(path))
  end

  task :fixtures => :environment do
    fedora_config = Rails.application.config_for(:fedora)
    fedora_server = ActiveFedora::Base.connection_for_pid('actest:1')

    # Ingest the actest:1 aggregator, actest:2 + actest:4 assets
    Dir.glob('spec/fixtures/fedora_objs/actest_*.xml') do |path|
      pid = File.basename(path, '.xml').sub('_',':')
      fedora_server.ingest(pid: pid, file: File.read(path))
    end

    # Create the descMetadata datastream on actest:1 with the MODS metadata
    fedora_server.add_datastream(
      pid: 'actest:1', dsid: 'descMetadata', dsLabel: 'descMetadata',
      content: File.open('spec/fixtures/fedora_objs/mods.xml'),
      controlGroup: 'M', mimeType: 'text/xml'
    )

    # Create the CONTENT datastream on actest:2 with the pdf fixture
    fedora_server.add_datastream(
      pid: 'actest:2', dsid: 'CONTENT', dsLabel: 'alice_in_wonderland.pdf',
      content: File.open('spec/fixtures/fedora_objs/alice_in_wonderland.pdf'),
      controlGroup: 'M', mimeType: 'application/pdf'
    )

    # Create the content datastream on actest:4 with the pdf fixture
    fedora_server.add_datastream(
      pid: 'actest:4', dsid: 'content', dsLabel: 'to_solr.json',
      content: File.open('spec/fixtures/fedora_objs/to_solr.json'),
      controlGroup: 'M', mimeType: 'application/json'
    )
  end
end
