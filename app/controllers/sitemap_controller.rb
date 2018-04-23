class SitemapController < ApplicationController
  include Blacklight::SearchHelper

  after_action :sweep_cache, only: :index

  def index
    @latest_doc = latest_doc
    @latest_time = Time.zone.parse(@latest_doc['record_creation_dtsi'])
    if stale?(etag: @latest_doc, last_modified: @latest_time.utc)
      key_parms = {
        controller: :sitemap, action: :index,
        record_creation_dtsi: @latest_time.to_i
      }
      @sitemap_cache_key = fragment_cache_key(key_parms)
      respond_to do |format|
        format.xml do
          headers['Content-Type'] = 'application/xml'
          headers['Last-Modified-Date'] = Time.zone.parse(@latest_doc['record_creation_dtsi']).utc.httpdate
          render layout: false, template: 'sitemap/map', formats: :xml, handlers: :builder
        end
      end
    end
  end

  # refactor: this solr call is very similar to the one in
  # catalog_helper custom_results() - but that relies on params
  # and modifies pub_date
  def fetch_latest(rows = 1, latest = nil)
    opts = { rows: rows, q: '' }
    if latest
      opts[:fq] = "record_creation_dtsi:[* TO #{latest}]"
    end
    opts[:fl] = 'id, record_creation_dtsi'
    opts[:sort] = 'record_creation_dtsi desc'
    # this is the upper limit for a single sitemap, see sitemap.org
    repository.search(opts)
  end

  def latest_doc
    fetch_latest(1).docs.first
  end

  def sweep_matcher
    Regexp.new('.*\/sitemap\.xml\?record_creation_dtsi=(?!' + @latest_time.to_i.to_s + ')\d+')
  end

  def sweep_cache
    # expire_fragment(sweep_matcher)
    cache_store.delete_matched(sweep_matcher)
  end
end
