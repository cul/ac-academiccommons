require File.expand_path(File.dirname(__FILE__) + '../../../lib/ac_indexing.rb')
namespace :ci do
  task :load_collection => :environment do
    fedora_config = Rails.application.config.fedora
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    # ingest the actest:1 aggregator
    path = "spec/fixtures/collection_3.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.post(:method => "/objects", :request => "collection:3", :body => File.read(path))
  end
  task :load_fixtures => :environment do
    fedora_config = Rails.application.config.fedora
    fedora_server = Cul::Fedora::Server.new(fedora_config)
    # ingest the actest:1 aggregator
    path = "spec/fixtures/actest_1/actest_1.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.post(:method => "/objects", :request => "actest:1", :body => File.read(path))
    # ingest the actest:3 metadata
    path = "spec/fixtures/actest_1/actest_3.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.post(:method => "/objects", :request => "actest:3", :body => File.read(path))
    # ingest the actest:2 resource object
    path = "spec/fixtures/actest_1/actest_2.xml"
    raise "#{path} does not exists" unless File.exists?(path)
    fedora_server.post(:method => "/objects", :request => "actest:2", :body => File.read(path))
    # create the CONTENT datastream on actest:2 with the pdf fixture
    path = "spec/fixtures/actest_1/alice_in_wonderland.pdf"
    fedora_server.post_multipart(:method => "/objects", :pid => "actest:2", :sdef => "datastreams",
                          :request => 'CONTENT', :body => File.open(path), :controlGroup => 'M',
                          :dsLabel => 'alice_in_wonderland.pdf', :mimeType => 'application/pdf')
    # index actest:1 
  end
end