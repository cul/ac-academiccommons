class SolrController < ApplicationController
  def get_index
     
    render :xml => index_ac2(params[:id]).to_xml
  
  end

  def index_ac2(pid)
    uri_prefix = "info:fedora/"
   

    hc = HTTPClient.new()
    
    fedora_url = "#{FEDORA_CONFIG[:riurl]}/get/"
    urls = {
      :rels => fedora_url + pid + "/RELS-EXT",
      :members => fedora_url + pid +  "/ldpd:sdef.Aggregator/listMembers?max=&format=&start=",
      :describes => fedora_url + pid + "/ldpd:sdef.Core/describedBy?max=&format=&start="
    }
   
    docs = {}
    urls.each_pair do |key, url|
      docs[key] = Nokogiri::XML(hc.get_content(url))
    end

    collections = docs[:rels].xpath("/rdf:RDF/rdf:Description/*[local-name()='memberOf']").collect { |m| m.attributes["resource"].value.sub(uri_prefix, "")  }

    members = docs[:members].css("member").to_enum(:each_with_index).collect do |member, i|
      {
        :pid => (member_pid = member.attributes["uri"].value.sub(uri_prefix, "")),
        :position => i,
        :url => fedora_url + member_pid + "/CONTENT"
      }
            
    end

    meta_pid = docs[:describes].at_css("sparql>results>result>description")
    if meta_pid
      meta_pid = meta_pid.attributes["uri"].value.sub(uri_prefix,"") 
      docs[:meta_pid] = Nokogiri::XML(hc.get_content(fedora_url + meta_pid + "/CONTENT"))
    end
    
    normalize_space = lambda { |s| s.to_s.strip.gsub(/\s{2,}/," ") }
    roles = ["Author","author","Creator","Thesis Advisor","Collector","Owner","Speaker","Seminar Chairman","Secretary","Rapporteur","Committee Member","Degree Grantor","Moderator","Editor","Interviewee","Interviewer","Organizer of Meeting","Originator","Teacher"]
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.add {
        xml.doc_ {
          xml.field(:name => "pid") { xml.text pid }
          
          collections.each do |collection|
            xml.field(:name => "member_of") { xml.text collection }
          end

          if (mods = docs[:meta_pid].at_css("mods"))
            title = normalize_space.call(mods.css("titleInfo>nonSort,title").collect(&:content).join(" "))
            xml.field(:name => "title_display") { xml.text title }
            xml.field(:name => "title_search") { xml.text title }
          
            mods.css("name[@type='personal']").each do |name_node|
              if name_node.css("role>roleTerm[@type='text']").collect(&:content).any_in?(*roles)
                
                fullname = (name_node.css("namePart[@type='family']").collect(&:content) | name_node.css("namePart[@type='given']").collect(&:content)).join(", ")
                
                
                xml.field(:name => "author_search") { xml.text fullname.downcase }
                xml.field(:name => "author_facet") { xml.text fullname }

              end
              
            end
              

          end

          
        }
      }

    
    end

    return builder 
  end


end
