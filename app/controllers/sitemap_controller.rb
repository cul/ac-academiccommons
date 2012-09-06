class SitemapController < ApplicationController

include Blacklight::SolrHelper

      def index

#refactor: this solr call is very similar to the one in catalog_helper custom_results() - but that relies on 
# params and modifies pub_date 

    q = ""
    fl = "title_display, id, author_facet, author_display, record_creation_date, handle"
    sort = "record_creation_date desc"
#this is the upper limit for a single sitemap, see sitemap.org
    rows = "50000"

    solr_response = force_to_utf8(Blacklight.solr.find(:q => q, :fl => fl, :sort => sort, :start => 0, :rows => rows))
    document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc, solr_response)}

    headers['Content-Type'] = 'application/xml'
    latest = document_list.first

     	     if stale?(:etag => latest, :last_modified => Time.zone.parse(latest["record_creation_date"][0]).utc)
		 @docs = document_list
	         @response = solr_response
		 respond_to do |format| 
	    	   format.xml { render :layout => false, :template => 'sitemap/map', :formats => :xml, :handlers => :builder and return}
	         end
	      end
     end
end