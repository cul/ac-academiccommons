xml.instruct! :xml, :version=>"1.0", :encoding=>"utf-8"

xml.urlset(:xmlns=>"http://www.sitemaps.org/schemas/sitemap/0.9") do
    @docs.each do |doc|
      xml.url do
        xml.loc(catalog_url(doc[:id]))
        xml.lastmod(doc[:record_creation_date][0])
    	xml.changefreq("yearly")
        xml.priority("0.5")
      end
    end
end