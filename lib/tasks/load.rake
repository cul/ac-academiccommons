namespace :load do
  task fixtures: :environment do
    fedora_config = Rails.application.config_for(:fedora)
    fedora_server = ActiveFedora::Base.connection_for_pid('actest:1')

    # Ingest the actest:1 aggregator, actest:2 + actest:3 + actest:4 assets
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
      pid: 'actest:3', dsid: 'content', dsLabel: 'alice_in_wonderland_video.mp4',
      content: File.open('spec/fixtures/fedora_objs/alice_in_wonderland_video.mp4'),
      controlGroup: 'M', mimeType: 'video/mp4'
    )

    # Create access datastream on actest:4 referencing access copy
    fedora_server.add_datastream(
      pid: 'actest:3', dsid: 'access', dsLabel: 'access.mp4',
      dsLocation: 'file:' + Rails.root.join('spec', 'fixtures', 'fedora_objs', 'alice_in_wonderland_video.mp4').to_s,
      controlGroup: 'E', mimeType: 'video/mp4', versionable: false
    )

    # Create the content datastream on actest:4 with the pdf fixture
    fedora_server.add_datastream(
      pid: 'actest:4', dsid: 'content', dsLabel: 'alice_in_wonderland_cover.jpg',
      content: File.open('spec/fixtures/fedora_objs/alice_in_wonderland_cover.jpg'),
      controlGroup: 'M', mimeType: 'image/jpeg'
    )

    # Create access datastream on actest:4 referencing access copy
    fedora_server.add_datastream(
      pid: 'actest:4', dsid: 'access', dsLabel: 'access.jpg',
      dsLocation: 'file:' + Rails.root.join('spec', 'fixtures', 'fedora_objs', 'alice_in_wonderland_cover.jpg').to_s,
      controlGroup: 'E', mimeType: 'image/jpeg', versionable: false
    )
  end
end
