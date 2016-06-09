class SitemapController < ApplicationController
  include Blacklight::SolrHelper
  after_filter :sweep_cache, :only => :index
  def index

    @latest_doc = latest_doc
    @latest_time = Time.zone.parse(@latest_doc["record_creation_date"])
    if stale?(:etag => @latest_doc, :last_modified => @latest_time.utc)
      key_parms = {
        :controller => 'sitemap', :action => 'index',
        :record_creation_date => @latest_time.to_i
      }
      @sitemap_cache_key = fragment_cache_key(key_parms)
      respond_to do |format|
        format.xml do
          headers['Content-Type'] = 'application/xml'
          headers['Last-Modified-Date'] = Time.zone.parse(@latest_doc["record_creation_date"]).utc.httpdate
          render :layout => false, :template => 'sitemap/map', :formats => :xml, :handlers => :builder
        end
      end
    end
  end

  # refactor: this solr call is very similar to the one in
  # catalog_helper custom_results() - but that relies on params
  # and modifies pub_date
  def fetch_latest(rows = 1, latest = nil)
    opts = {:rows => rows, :q => ''}
    if latest
      opts[:fq] = "record_creation_date:[* TO #{latest}]"
    end
    opts[:fl] = "id, record_creation_date"
    opts[:sort] = "record_creation_date desc"
    # this is the upper limit for a single sitemap, see sitemap.org
    force_to_utf8(Blacklight.solr.find(opts))
  end

  def latest_doc
    solr_response = fetch_latest(1)
    SolrDocument.new(solr_response.docs.first, solr_response)
  end

  def sweep_matcher
    Regexp.new('.*\/sitemap\.xml\?record_creation_date=(?!' + @latest_time.to_i.to_s + ')\d+')
  end

  def sweep_cache
    # expire_fragment(sweep_matcher)
    cache_store.delete_matched(sweep_matcher)
  end
end