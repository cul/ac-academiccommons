# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = 'http://www.example.com'

SitemapGenerator::Sitemap.create do
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host

  # Add static pages
  add about_path,      priority: 0.7, changefreq: 'monthly'
  add policies_path,   priority: 0.7, changefreq: 'monthly'
  add faq_path,        priority: 0.7, changefreq: 'monthly'
  add developers_path, priority: 0.7, changefreq: 'monthly'

  # Add all items
  items = AcademicCommons.search { |p| p.aggregators_only }.docs
  items.each do |item| # could use fl parameter for better performance
    add solr_document_path(item.id), priority: 0.5, changefreq: 'yearly', lastmod: item['record_change_dtsi']
  end
end
