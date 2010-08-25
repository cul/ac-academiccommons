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
    search_to_content = lambda { |x| x.kind_of?(Nokogiri::XML::Element) ? x.content : x.to_s }
    add_field = lambda { |x, name, value| x.field(:name => name) { x.text search_to_content.call(value) }}

    get_fullname = lambda { |node| node.nil? ? nil : (node.css("namePart[@type='family']").collect(&:content) | node.css("namePart[@type='given']").collect(&:content)).join(", ") }

    roles = ["Author","author","Creator","Thesis Advisor","Collector","Owner","Speaker","Seminar Chairman","Secretary","Rapporteur","Committee Member","Degree Grantor","Moderator","Editor","Interviewee","Interviewer","Organizer of Meeting","Originator","Teacher"]
    
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.add {
        xml.doc_ {
          add_field.call(xml, "pid", pid)
          
          collections.each do |collection|
            add_field.call(xml, "member_of", collection)
          end

          if (mods = docs[:meta_pid].at_css("mods"))
            title = normalize_space.call(mods.css("titleInfo>nonSort,title").collect(&:content).join(" "))
            add_field.call(xml, "title_display", title)
            add_field.call(xml, "title_search", title)
         
            all_names = []
            mods.css("name[@type='personal']").each do |name_node|
              if name_node.css("role>roleTerm[@type='text']").collect(&:content).any_in?(*roles)
                
                fullname = get_fullname.call(name_node)
                
                all_names << fullname
                
                add_field.call(xml, "author_search", fullname.downcase)
                add_field.call(xml, "author_facet", fullname)

              end
              
            end

            add_field.call(xml, "authors_display",all_names.join("; "))
            add_field.call(xml, "date", mods.at_css("*[@keyDate='yes']"))

            mods.css("genre").each do |genre_node|
              add_field.call(xml, "genre_facet", genre_node)
              add_field.call(xml, "genre_search", genre_node)

            end
              

            add_field.call(xml, "abstract", mods.at_css("abstract"))
            add_field.call(xml, "handle", mods.at_css("identifier[@type='hdl']"))
         
            mods.css("subject:not([@authority='local'])>topic").each do |topic_node|
              add_field.call(xml, "keyword_search", topic_node.content.downcase)
              add_field.call(xml, "keyword_facet", topic_node)
            end

            mods.css("subject[@authority='local']>topic").each do |topic_node|
              add_field.call(xml, "subject", topic_node)
              add_field.call(xml, "subject_search", topic_node)
            end


            add_field.call(xml, "tableOfContents", mods.at_css("tableOfContents"))
            
            mods.css("note").each { |note| add_field.call(xml, "notes", note) }
            
            related_host = mods.at_css("relatedItem[@type='host']")

            book_journal_title = related_host.at_css("titleInfo>title")

            if book_journal_title
              book_journal_subtitle = mods.at_css("name>titleInfo>subTitle")
              
              book_journal_title = book_journal_title.content + ": " + book_journal_subtitle.content.to_s if book_journal_subtitle

            end

            add_field.call(xml, "book_journal_title", book_journal_title)

            add_field.call(xml, "book_author", get_fullname.call(related_host.at_css("name")))
  
            add_field.call(xml, "issn", related_host.at_css("identifier[@type='issn']"))
            add_field.call(xml, "publisher", mods.at_css("relatedItem>originInfo>publisher"))
            add_field.call(xml, "publisher_location", mods.at_css("relatedItem > originInfo>place>placeTerm[@type='text']"))
            add_field.call(xml, "isbn", mods.at_css("relatedItem>identifier[@type='isbn']"))
            add_field.call(xml, "doi", mods.at_css("identifier[@type='doi'][@displayLabel='Published version']"))
            
            mods.css("physicalDescription>internetMediaType").each { |mt| add_field.call(xml, "media_type_facet", mt) }

            mods.css("typeOfResource").each { |tr| add_field.call(xml, "type_of_resource_facet", tr)}
            mods.css("subject>geographic").each do |geo|
              add_field.call(xml, "geographic_area", geo)
              add_field.call(xml, "geographic_area_search", geo)
            end


            
          end

          members.each do |member|
            add_field.call(xml, "ac.fulltext_#{member[:position]}", member[:full_text])
          end
          
        }
      }

    
    end

    return builder 

  end


end
