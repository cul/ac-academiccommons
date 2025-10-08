# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = Rails.application.config.default_host
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps'

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
  puts 'Inside sitemap create block!'
  add about_path,      priority: 0.7, changefreq: 'monthly'
    puts "     adding #{about_path}"
  add policies_path,   priority: 0.7, changefreq: 'monthly'
    puts "     adding #{policies_path}"
  add faq_path,        priority: 0.7, changefreq: 'monthly'
    puts "     adding #{faq_path}"
  add developers_path, priority: 0.7, changefreq: 'monthly'
    puts "     adding #{developers_path}"

  # Add all items
  items = AcademicCommons.search { |p| p.aggregators_only.field_list('id', 'record_change_dtsi') }.docs
  puts "Adding #{items.length} items"
  items.each do |item|
    puts "     adding #{solr_document_path(item.id)}"
    add solr_document_path(item.id), priority: 0.5, changefreq: 'yearly', lastmod: item['record_change_dtsi']
  end
end
