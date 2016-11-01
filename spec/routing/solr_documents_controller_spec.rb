require 'rails_helper'

describe SolrDocumentsController, :type => :routing do
  describe "routing" do
    it "routes to #update" do
      expect(:put => "/solr_documents/foo").to route_to(controller: "solr_documents", action:"update", id:"foo")
    end
    it "routes to #destroy" do
      expect(:delete => "/solr_documents/foo").to route_to(controller: "solr_documents", action:"destroy", id:"foo")
    end
    it "routes to #show" do
      expect(:head => "/solr_documents/foo").to route_to(controller: "solr_documents", action:"show", id:"foo")
    end
  end
end