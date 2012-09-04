Feature: Generate Sitemap.xml for Search Engines
 In order to inform search spiders of our latest content
 I want to make a sitemap.xml file accessible

Scenario: new indexed records
 When I go to the sitemap
 And the sitemap is stale
 Then AC responds with a current sitemap


Scenario: no new indexed records
 When I go to the sitemap
 And the sitemap is fresh
 Then AC responds that the sitemap is unmodified


