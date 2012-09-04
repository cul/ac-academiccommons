When /^the sitemap is stale$/ do
  sitemap_is_stale.should be_true
end

When /^AC responds with a current sitemap$/ do
     page.should have_selector('urlset')
end

When /^the sitemap is fresh$/ do
sitemap_is_stale.should be_false
end

Then /^AC responds that the sitemap is unmodified$/ do
     response.should 
end