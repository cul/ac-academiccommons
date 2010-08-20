require 'rubygems'
require 'net/https'
require 'rexml/document'
require 'nokogiri'
require 'xml/xslt'
require 'logger'

@uri_prefix = "info:fedora/"

pid = ARGV[0]
url = ARGV[1]

relurl = "#{url}/get/#{pid}/RELS-EXT"

#create a doc to which the following data will be added
indoc = REXML::Document.new()
e1 = indoc.add_element "doc"

# call rels-ext to get member_of info

# get the XML data as a string
uri = URI.parse(relurl)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)
xml_data = response.body

doc = REXML::Document.new(xml_data)

  ePID = e1.add_element "pid"
  ePID.text = pid


xpath = "rdf:RDF/rdf:Description/cul:memberOf"

if(doc.elements['rdf:RDF/rdf:Description/memberOf'] && !doc.elements[xpath])
	xpath = "rdf:RDF/rdf:Description/memberOf"
end

#collections that PID is member of
  e2 = e1.add_element "collection"

#doc.elements.each('rdf:RDF/rdf:Description/cul:memberOf') do |ele|

doc.elements.each(xpath) do |ele|
  current_pid = ele.attributes["rdf:resource"].sub(@uri_prefix, "")
  e3 = e2.add_element "member"
  e3.text = current_pid
end

resources = e1.add_element "resources"
resourceUrl = "#{url}/get/#{pid}/ldpd:sdef.Aggregator/listMembers?max=&format=&start="


# get the XML data as a string

uri = URI.parse(resourceUrl)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)
resData = response.body

resDoc = REXML::Document.new(resData)
counter = 1
resDoc.elements.each('//member') do |ele|
  resource_pid = ele.attributes["uri"].sub(@uri_prefix, "")						    
  resource = resources.add_element "resource"
  resource.attributes['pid'] = resource_pid
  resource.attributes['position'] = counter.to_s()
  resource_url = "#{url}/get/#{resource_pid}/CONTENT"

  c_file = File.new("./CONTENT", "w")

  contentData = %x[curl #{resource_url}]
  c_file.print contentData

#  xresult = %x[java -jar ./tika-0.3/tika-0.3.jar -t ./CONTENT]
#  xresult.gsub!(/[^\w\s]/, '')	
#  resource.text = xresult
  File.delete('./CONTENT')
  counter += 1
end

  doc = Nokogiri::XML(indoc.to_s)
  xslt  = Nokogiri::XSLT(File.read('/Users/Will/getIndex/ac2.xslt'))

  solrdoc = xslt.transform(doc, Nokogiri::XSLT.quote_params(['repositoryService', 'https://repository2.cul.columbia.edu:8443/fedora']))


  #   print solrdoc;






