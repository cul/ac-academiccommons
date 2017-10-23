namespace :load do
  task :collection => :environment do
    fedora_config = Rails.application.config_for(:fedora)
    fedora_server = ActiveFedora::Base.connection_for_pid("collection:3")
    # ingest the actest:1 aggregator
    path = "spec/fixtures/collection_3.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.ingest(pid: "collection:3", file: File.read(path))
  end

  task :fixtures => :environment do
    fedora_config = Rails.application.config_for(:fedora)
    fedora_server = ActiveFedora::Base.connection_for_pid("actest:1")
    # ingest the actest:1 aggregator
    Dir.glob("spec/fixtures/actest_1/actest_*.xml") do |path|
        pid = File.basename(path, ".xml").sub('_',':')
        fedora_server.ingest(pid: pid, file: File.read(path))
    end

    # create the CONTENT datastream on actest:2 with the pdf fixture
    path = "spec/fixtures/actest_1/alice_in_wonderland.pdf"
    fedora_server.add_datastream(pid: "actest:2", dsid: 'CONTENT', content: File.open(path), :controlGroup => 'M',
                          :dsLabel => 'alice_in_wonderland.pdf', :mimeType => 'application/pdf')
    # create the content datastream on actest:4 with the pdf fixture
    path = "spec/fixtures/actest_1/to_solr.json"
    fedora_server.add_datastream(pid: "actest:4", dsid: 'content', content: File.open(path), :controlGroup => 'M',
                          :dsLabel => 'to_solr.json', :mimeType => 'application/json')
  end
end
