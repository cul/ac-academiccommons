require File.expand_path(File.dirname(__FILE__) + '../../../lib/ac_indexing.rb')
namespace :ci do
  task :load_collection => :environment do
    fedora_config = Rails.application.config.fedora
    fedora_server = ActiveFedora::Base.connection_for_pid("collection:3")
    # ingest the actest:1 aggregator
    path = "spec/fixtures/collection_3.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.ingest(pid: "collection:3", file: File.read(path))
  end
  task :load_fixtures => :environment do
    fedora_config = Rails.application.config.fedora
    fedora_server = ActiveFedora::Base.connection_for_pid("actest:1")
    # ingest the actest:1 aggregator
    path = "spec/fixtures/actest_1/actest_1.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.ingest(pid: "actest:1", file: File.read(path))
    # ingest the actest:3 metadata
    path = "spec/fixtures/actest_1/actest_3.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.ingest(pid: "actest:3", file: File.read(path))
    # ingest the actest:2 resource object
    path = "spec/fixtures/actest_1/actest_2.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.ingest(pid: "actest:2", file: File.read(path))
    # create the CONTENT datastream on actest:2 with the pdf fixture
    path = "spec/fixtures/actest_1/alice_in_wonderland.pdf"
    fedora_server.add_datastream(pid: "actest:2", dsid: 'CONTENT', content: File.open(path), :controlGroup => 'M',
                          :dsLabel => 'alice_in_wonderland.pdf', :mimeType => 'application/pdf')
    # index actest:1 
  end
end