require "open3"
begin
  require "active_support/core_ext/array/extract_options"
rescue
  require "activesupport"
end

module Cul
  module Fedora
    class Item
      
      attr_reader :server, :pid
      include Open3 

      URI_TO_PID = 'info:fedora/'
      MAX_LIST_MEMBERS_PER_REQUEST = 500

      def <=>(other)
        pid <=> other.pid
      end

      def pid_escaped
        pid.gsub(/:/,'\\:')
      end

      def initialize(*args)
        options = args.extract_options!
        @server = options[:server] || Server.new(options[:server_config])
        @logger = options[:logger]
        @pid = options[:pid] || options[:uri] || raise(ArgumentError, "requires uri or pid")
        @pid = @pid.to_s.sub(URI_TO_PID, "")
      end

      def logger
        @logger ||= Logger.new
      end

      def ==(other)
        self.server == other.server
        self.pid == other.pid
      end

      def exists?
        begin
          request
          return true
        rescue Exception => e # we should really do some better checking of error type etc here
    logger.error "no object was found for fedora pid  #{pid}"
          logger.error e.message
          return false
        end
      end

      def request(options = {})
        @server.request(options.merge(:pid => @pid))
      end

      def request_path(options = {})
        @server.request_path(options.merge(:pid => @pid))
      end

      def getIndex(profile = "raw")
        Nokogiri::XML(request(:request => "getIndex", :sdef => "ldpd:sdef.Core", :profile => profile))
      end

      def datastream(name)
        request(:request => name.to_s.upcase)
      end


      def risearch_for_members()
        results = JSON::parse(@server.request(:method => "", :request => "risearch", :format => "json", :lang => "itql", :query => sprintf(@server.riquery, @pid)))["results"]

        results.collect { |r| @server.item(r["member"]) }

      end

      def listMembers()
        begin
          i = 1
          size = getSize
          items = []
          while (i <= size)
            result = Nokogiri::XML(request(:method => "/objects", :sdef => "methods/ldpd:sdef.Aggregator", :request => "listMembers", :format => "sparql", :max => MAX_LIST_MEMBERS_PER_REQUEST, :start => (i - 1)))

            result.css("sparql>results>result>member").collect do |result_node|
              items << @server.item(result_node.attributes["uri"].value)
            end
            i = i + MAX_LIST_MEMBERS_PER_REQUEST
          end
          return items
        rescue Exception => e
          
          Rails.logger.info "======= tika listMembers error: " + e.message
          
          logger.error e.message
          []
        end
      end

      def getSize()
        begin
          request(:method => "/objects", :sdef => "methods/ldpd:sdef.Aggregator", :request => "getSize").to_i
        rescue Exception => e
          logger.error e.message
          return -1
        end
      end

      def describedBy
        begin
          params = {:method => '/objects', :request => "describedBy", :sdef => "methods/ldpd:sdef.Core"}
          result = request(params)
          Nokogiri::XML(result).css("sparql>results>result>description").collect do |metadata|
            @server.item(metadata.attributes["uri"].value)
          end
        rescue Exception => e
          logger.error e.message
          []
        end
      end

      def belongsTo
        begin
          result = Nokogiri::XML(datastream("RELS-EXT"))
          result.xpath("/rdf:RDF/rdf:Description/*[local-name()='memberOf']").collect do |member|
            @server.item(member.attributes["resource"].value)
          end
        rescue Exception => e
          logger.error e.message
          []
        end
      end
      
      def recordInfoIndexing(mods, add_field)

        if(record_content_source = mods.at_css("recordInfo>recordContentSource"))
          add_field.call("record_content_source", record_content_source)
        end

        if(record_creation_date = mods.at_css("recordInfo>recordCreationDate"))
          record_creation_date = DateTime.parse(record_creation_date.text.gsub("UTC", "").strip)
          add_field.call("record_creation_date", record_creation_date.strftime("%Y-%m-%dT%H:%M:%SZ"))
        end
        
        if(record_change_date = mods.at_css("recordInfo>recordChangeDate"))
          record_change_date = DateTime.parse(record_change_date.text.gsub("UTC", "").strip)
          add_field.call("record_change_date", record_change_date.strftime("%Y-%m-%dT%H:%M:%SZ"))
        end

        if(record_identifier = mods.at_css("recordInfo>recordIdentifier"))
          add_field.call("record_identifier", record_identifier)
        end
        
        if(record_language_of_catalog = mods.at_css("recordInfo>languageOfCataloging>languageTerm"))
          add_field.call("record_language_of_catalog", record_language_of_catalog)
        end       
        
        if(record_creation_date.nil? && !record_change_date.nil?)
          add_field.call("record_creation_date", record_change_date.strftime("%Y-%m-%dT%H:%M:%SZ"))
        end

      end
      
      def locationIndexing(mods, add_field)
        if(physicalLocation = mods.at_css("location>physicalLocation"))
          add_field.call("physical_location", physicalLocation)
        end
      end
      
      def languageIndexing(mods, add_field)
        if(language = mods.at_css("language>languageTerm"))
          add_field.call("language", language)
        end
      end
      
      def originInfoIndexing(mods, add_field)       

        if(publisher = mods.at_css("originInfo > publisher"))   
          if(!publisher.nil? && publisher.text.length != 0)      
            add_field.call("publisher", publisher)
          end
        end 
        
        if(location = mods.at_css("originInfo>place>placeTerm"))  
          if(!location.nil? && location.text.length != 0)       
            add_field.call("publisher_location", location)
          end
        end      

        if(dateIssued = mods.at_css("originInfo>dateIssued"))   
          if(!dateIssued.nil? && dateIssued.text.length != 0)      
            add_field.call("date_issued", dateIssued)
          end
        end  

        if(edition = mods.at_css("originInfo>edition"))    
          if(!edition.nil? && edition.text.length != 0)     
            add_field.call("edition", edition)
          end
        end 
        
      end
      
      def roleIndexing(mods, add_field)
        mods.css("role > roleTerm").each do |role|
          if(!role.nil? && role.text.length != 0)     
            add_field.call("role", role)
          end
        end
      end
      
      def identifierIndexing(mods, add_field)
        
        if(handle = mods.at_css("identifier[@type='CDRS doi']"))   
          if(!handle.nil? && handle.text.length != 0)      
            add_field.call("handle", handle)
          else
            add_field.call("handle", mods.at_css("identifier[@type='hdl']"))  
          end
        else
          add_field.call("handle", mods.at_css("identifier[@type='hdl']"))            
        end         
      
        if(isbn = mods.at_css("identifier[@type='isbn']"))   
          if(!isbn.nil? && isbn.text.length != 0)      
            add_field.call("isbn", isbn) 
          end
        end 
        
        if(doi = mods.at_css("identifier[@type='doi']"))   
          if(!doi.nil? && doi.text.length != 0)      
            add_field.call("doi", doi)
          end
        end 
        
        if(uri = mods.at_css("identifier[@type='uri']"))   
          if(!uri.nil? && uri.text.length != 0)      
            add_field.call("uri", uri)
          end
        end 
        
        if(issn = mods.at_css("identifier[@type='issn']"))   
          if(!issn.nil? && issn.text.length != 0)      
            add_field.call("issn", issn)
          end 
        end

      end
      
      def locationUrlIndexing(mods, add_field)
        if(locationUrl = mods.at_css("location > url"))   
          if(!locationUrl.nil? && locationUrl.text.length != 0)      
            add_field.call("url", locationUrl)
          end 
        end
      end   
      
      def embargo_release_date_indexing(mods, add_field)

        Rails.application.config.fedora

        if(free_to_read_start_date = mods.at_css("free_to_read"))
          if(free_to_read_start_date = mods.at_css("free_to_read")['start_date'])   
            if(!free_to_read_start_date.nil? && free_to_read_start_date.length != 0)   
               add_field.call("free_to_read_start_date", free_to_read_start_date)
               process_resource_activation(free_to_read_start_date, @pid)
            end 
          end
        end
      end   
      
      def process_resource_activation(free_to_read_start_date, aggregator_pid)

        begin
                  
          if(!check_if_free_to_read(free_to_read_start_date))
            return
          end  
          
          resource_pid = get_resource_pid(aggregator_pid) 

          if(check_if_resouce_is_available(resource_pid))
            return
          end  
          
          make_resource_active(resource_pid)
          
          logger.info "=== " + resource_pid + " is activated, as part of aggregator: " + aggregator_pid
          
        rescue Exception => e
          logger.error "=== process_resource() error ==="
          logger.error e.message
        end        
        
      end
      
      def check_if_free_to_read(free_to_read_start_date)
        embargo_release_date = Date.strptime(free_to_read_start_date, '%Y-%m-%d')
        current_date = Date.strptime(Time.now.strftime('%Y-%m-%d'), '%Y-%m-%d')
        return current_date > embargo_release_date
      end
      
      def get_resource_pid(aggregator_pid) 
        aggregator_members_url = Rails.application.config.fedora['open_url'] + '/objects/' + aggregator_pid + '/methods/ldpd:sdef.Aggregator/listMembers?format=sparql&max=1&start=0'
        response = Net::HTTP.get_response(URI(aggregator_members_url))
        contentXML = Nokogiri::XML(response.body.to_s)
        member_node = contentXML.css("member")
        resourse_pid = member_node.first['uri']
        return resourse_pid.sub('info:fedora/', '')
      end
      
      def check_if_resouce_is_available(resourse_pid)
        fedora_resourse_url = Rails.application.config.fedora['open_url'] + '/objects/' + resourse_pid
        response = Net::HTTP.get_response(URI(fedora_resourse_url))
        return response.code == '200'
      end

      def make_resource_active(resource_pid)
        change_resourse_state_url = Rails.application.config.fedora['pid_state_changer_url'] + '?pid=' + resource_pid + '&repository_id=2&state=A'
        Net::HTTP.get_response(URI(change_resourse_state_url))
      end

      def index_for_ac2(options = {})
        do_fulltext = options[:fulltext] || false
        do_metadata = options[:metadata] || true

        status = :success
        error_message = ""

        results = Hash.new { |h,k| h[k] = [] }
        normalize_space = lambda { |s| s.to_s.strip.gsub(/\s{2,}/," ") }
        search_to_content = lambda { |x| x.kind_of?(Nokogiri::XML::Element) ? x.content.strip : x.to_s.strip }
        add_field = lambda { |name, value| results[name] << search_to_content.call(value) }

        get_fullname = lambda { |node| node.nil? ? nil : (node.css("namePart[@type='family']").collect(&:content) | node.css("namePart[@type='given']").collect(&:content)).join(", ") }

        author_roles = ["author","creator","speaker","moderator","interviewee","interviewer","contributor"]
        advisor_roles = ["thesis advisor"]
        corporate_author_roles = ["author"]
        corporate_department_roles = ["originator"]
        resource_types = {'text' => 'Text', 'moving image' => 'Video', 'sound recording--nonmusical' => 'Audio', 'software, multimedia' => 'software', 'still image' => 'Image'}
 
        organizations = []
        departments = []
        originator_department = ""
          
        begin
          collections = self.belongsTo
          meta = describedBy.first

          meta = Nokogiri::XML(meta.datastream("CONTENT")) if meta
          mods = meta.at_css("mods") if meta

          if mods && do_metadata
            # baseline blacklight fields: id is the unique identifier, format determines by default, what partials get called
            add_field.call("id", @pid)
            add_field.call("internal_h",  collections.first.to_s + "/")
            add_field.call("pid", @pid)
            collections.each do |collection|
              add_field.call("member_of", collection)
            end

            recordInfoIndexing(mods, add_field)
            locationIndexing(mods, add_field)
            languageIndexing(mods, add_field)
            originInfoIndexing(mods, add_field)
            roleIndexing(mods, add_field)
            identifierIndexing(mods, add_field)
            locationUrlIndexing(mods, add_field)
            embargo_release_date_indexing(mods, add_field)

            title = mods.css("titleInfo>title").first.text
            title_search = normalize_space.call(mods.css("titleInfo>nonSort,title").collect(&:content).join(" "))

            add_field.call("title_display", title)
            add_field.call("title_search", title_search)

            all_author_names = []
            mods.css("name[@type='personal']").each do |name_node|
              
              fullname = get_fullname.call(name_node)
              note_org = false
              
              if name_node.css("role>roleTerm").collect(&:content).any? { |role| author_roles.include?(role) }

                note_org = true
                all_author_names << fullname
                if(!name_node["ID"].nil?)
                  add_field.call("author_uni", name_node["ID"])
                end
                
                author_affiliations = []
                
                name_node.css("affiliation").each do |affiliation_node|
                  author_affiliations.push(affiliation_node.text)
                end
                
                uni = name_node["ID"] == nil ? '' : name_node["ID"]
                
                add_field.call("author_info", fullname + " : " + uni + " : " + author_affiliations.join("; "))
                
                add_field.call("author_search", fullname.downcase)
                add_field.call("author_facet", fullname)
                
              elsif name_node.css("role>roleTerm").collect(&:content).any? { |role| advisor_roles.include?(role) }

                note_org = true
                first_role = name_node.at_css("role>roleTerm").text
                add_field.call(first_role.gsub(/\s/, '_'), fullname)
                
                add_field.call("advisor_uni", name_node["ID"])
                add_field.call("advisor_search", fullname.downcase)
              end
              
              if (note_org == true)
                name_node.css("affiliation").each do |affiliation_node|
                  affiliation_text = affiliation_node.text
                  if(affiliation_text.include?(". "))
                    affiliation_split = affiliation_text.split(". ")
                    organizations.push(affiliation_split[0].strip)
                    departments.push(affiliation_split[1].strip)
                  end
                end
              end
              
            end
            
            mods.css("name[@type='corporate']").each do |corp_name_node|
              if((!corp_name_node["ID"].nil? && corp_name_node["ID"].include?("originator")) || corp_name_node.css("role>roleTerm").collect(&:content).any? { |role| corporate_department_roles.include?(role) })
                name_part = corp_name_node.at_css("namePart").text
                if(name_part.include?(". "))
                  name_part_split = name_part.split(". ")
                  organizations.push(name_part_split[0].strip)
                  departments.push(name_part_split[1].strip)
                  originator_department = name_part_split[1].strip
                end
              end
              if corp_name_node.css("role>roleTerm").collect(&:content).any? { |role| corporate_author_roles.include?(role) }
                display_form = corp_name_node.at_css("displayForm") 
                if(!display_form.nil?)
                  fullname = display_form.text
                else
                  fullname = corp_name_node.at_css("namePart").text
                end
                all_author_names << fullname
                add_field.call("author_search", fullname.downcase)
                add_field.call("author_facet", fullname)
              end
            end

            add_field.call("author_display",all_author_names.join("; "))
            add_field.call("pub_date_facet", mods.at_css("*[@keyDate='yes']"))

            mods.css("genre").each do |genre_node|
              add_field.call("genre_facet", genre_node)
              add_field.call("genre_search", genre_node)
            end

            add_field.call("abstract", mods.at_css("abstract"))
            #add_field.call("handle", mods.at_css("identifier[@type='hdl']"))
  
            mods.css("subject").each do |subject_node|
              if(subject_node.attributes.count == 0)
                subject_node.css("topic").each do |topic_node|
                  add_field.call("keyword_search", topic_node.content.downcase)
                  add_field.call("subject_facet", topic_node)
                  add_field.call("subject_search", topic_node)
                end
              end
            end

            add_field.call("originator_department", originator_department)  
            add_field.call("table_of_contents", mods.at_css("tableOfContents"))

            mods.css("note").each { |note| add_field.call("notes", note) }

            if (related_host = mods.at_css("relatedItem[@type='host']"))
              book_journal_title = related_host.at_css("titleInfo>title") 

              if book_journal_title
                book_journal_subtitle = mods.at_css("name>titleInfo>subTitle")

                book_journal_title = book_journal_title.content + ": " + book_journal_subtitle.content.to_s if book_journal_subtitle

              end
              
              if(volume = related_host.at_css("part>detail[@type='volume']>number"))
                add_field.call("volume", volume)                 
              end            
              
              if(issue = related_host.at_css("part>detail[@type='issue']>number"))
                add_field.call("issue", issue)                 
              end
              
              if(start_page = related_host.at_css("part > extent[@unit='page'] > start"))
                add_field.call("start_page", start_page)               
              end
              
              if(end_page = related_host.at_css("part > extent[@unit='page'] > end"))
                add_field.call("end_page", end_page)                
              end  
              
              if(date = related_host.at_css("part > date"))
                add_field.call("date", date)            
              end            
              
              add_field.call("book_journal_title", book_journal_title)

              add_field.call("book_author", get_fullname.call(related_host.at_css("name"))) 

            end
            
            if(related_series = mods.at_css("relatedItem[@type='series']"))
              if(related_series.has_attribute?("ID"))
                add_field.call("series_facet", related_series.at_css("titleInfo>title"))
              else
                add_field.call("non_cu_series_facet", related_series.at_css("titleInfo>title"))
              end  
              add_field.call("part_number", related_series.at_css("titleInfo>partNumber"))
            end

            mods.css("physicalDescription>internetMediaType").each { |mt| add_field.call("media_type_facet", mt) }

            mods.css("typeOfResource").each { |tr| 
    add_field.call("type_of_resource_mods", tr)
          type = tr.text
        if(resource_types.has_key?(type))
      type = resource_types[type]
    end
    add_field.call("type_of_resource_facet", type)
      }

            mods.css("subject>geographic").each do |geo|
              add_field.call("geographic_area_display", geo)
              add_field.call("geographic_area_search", geo)
            end

            # This is just a placeholder, reminding us that we need to implement citations in some way
            # add_field.call("export_as_mla_citation_txt","")
            
            if(organizations.count > 0)
              organizations = organizations.uniq
              organizations.each do |organization|
                add_field.call("organization_facet", organization)
              end
            end
            
            if(departments.count > 0)
              departments = departments.uniq
              departments.each do |department|
                add_field.call("department_facet", department.to_s.sub(", Department of", "").strip)
              end
            end
            
          end
          
          if(do_fulltext) ## ===   fulltext_processing === does not work correctly if move it to separate method
            
            Rails.logger.debug "======= fulltext started === "
              
             listMembers.each_with_index do |member, i|
    
                begin
    
                resource_file = Rails.application.config.indexing['temp_directory'] + member.pid.sub(':', "_")
                
                Rails.logger.debug "======= fulltext resource file: " + resource_file
    
                download_command = "curl " +  Rails.application.config.fedora['riurl'] + "/objects/#{member.pid}/datastreams/CONTENT/content > " + resource_file
                
                Rails.logger.debug "======= fulltext download_command === " + download_command 
                
                Open3.popen3(download_command)
                
                text_extract_command = "java -jar " + Rails.application.config.indexing['text_extractor_jar_file'] + " -t #{resource_file}"
                
                Rails.logger.debug "======= fulltext text_extract_command === " + text_extract_command
                
                Open3.popen3(text_extract_command) do |stdin, stdout, stderr|
    
                    tika_result = []
                    tika_result = stdout.readlines
                    
                    add_field.call("ac.fulltext_#{i}", tika_result)

                    File.delete(resource_file)
                 end
                 
                rescue Exception => e
                  status = :error
                  error_message += e.message
                  Rails.logger.debug "======= fulltext indexing error: " + e.message
                end
                
                 Rails.logger.debug "======= fulltext finished === "
              end            
          end   ##========================  fulltext_processing end ======================== #

        rescue Exception => e
          status = :error
          error_message += e.message
          Rails.logger.info "=== indexing error: " + e.message
        end

        status = :invalid_format  if results.empty?

        return {:status => status, :error_message => error_message, :results => results}

      end

      def to_s
        @pid
      end
    end
  end
end
