module AcademicCommons
  module Indexable
    AUTHOR_ROLES = %w(author creator speaker moderator interviewee interviewer contributor).freeze
    ADVISOR_ROLES = ["thesis advisor"].freeze
    CORPORATE_AUTHOR_ROLES = ["author"].freeze
    CORPORATE_DEPARTMENT_ROLES = ["originator"].freeze
    RESOURCE_TYPES = {'text' => 'Text', 'moving image' => 'Video', 'sound recording--nonmusical' => 'Audio', 'software, multimedia' => 'software', 'still image' => 'Image'}.freeze
    # this is documentary, and should go away when this module is a concern
    REQUIRED_METHODS = [:belongs_to, :descMetadata_content]

    def index_descMetadata(solr_doc={})
      raise "called index_descMetadata twice" if (@index_descMetadata ? (@index_descMetadata += 1) : (@index_descMetadata = 1)) > 1

      meta = descMetadata_datastream
      raise "descMetadata COULD NOT be found for #{self.pid}.\nSolr doc: #{solr_doc.inspect}" unless meta

      solr_doc["described_by_ssim"] = ["info:fedora/#{meta.pid}/#{meta.dsid}"]
      document = Nokogiri::XML(meta.content).remove_namespaces!
      mods = document.at_css("mods")

      collections = self.belongs_to
      normalize_space = lambda { |s| s.to_s.strip.gsub(/\s{2,}/," ") }
      search_to_content = lambda { |x| x.kind_of?(Nokogiri::XML::Element) ? x.content.strip : x.to_s.strip }
      add_field = lambda { |name, value| solr_doc[name] ? (solr_doc[name] << search_to_content.call(value)) : (solr_doc[name] = [search_to_content.call(value)]) }

      organizations = []
      departments = []
      originator_department = ""
      # baseline blacklight fields: id is the unique identifier, format determines by default, what partials get called
      #TODO: Make sure access is indifferent
      add_field.call("id", self.pid) unless (solr_doc["id"] || solr_doc[:id])
      add_field.call("internal_h",  collections.first.to_s + "/")
      add_field.call("pid", self.pid) unless (solr_doc["pid"] || solr_doc[:pid])
      collections.each do |collection|
        add_field.call("member_of", collection)
      end

      recordInfoIndexing(mods, add_field)
      locationIndexing(mods, add_field)
      languageIndexing(mods, add_field)
      originInfoIndexing(mods, add_field)
      solr_doc['role'] = roleIndexing(mods, add_field)
      persistent_uri(mods, add_field)
      identifierIndexing(mods, add_field)
      locationUrlIndexing(mods, add_field)
      embargo_release_date_indexing(mods, add_field)
      degree_indexing(mods, add_field)

      title = mods.css(">titleInfo>title")
      related_titles = mods.css("relatedItem[@type='host']:not([displayLabel=Project])>titleInfo").css(">nonSort,title")

      title_search = normalize_space.call((title + related_titles).collect(&:content).join(" "))

      add_field.call("title_display", title.first.text)
      add_field.call("title_search", title_search)

      all_author_names = []
      mods.css("name[@type='personal']").each do |name_node|

        fullname = get_fullname(name_node)
        note_org = false

        if name_node.css("role>roleTerm").collect(&:content).any? { |role| AUTHOR_ROLES.include?(role.downcase) }

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

        elsif name_node.css("role>roleTerm").collect(&:content).any? { |role| ADVISOR_ROLES.include?(role.downcase) }

          note_org = true
          first_role = name_node.at_css("role>roleTerm").text
          add_field.call(first_role.downcase.gsub(/\s/, '_'), fullname)

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
        if((!corp_name_node["ID"].nil? && corp_name_node["ID"].include?("originator")) || corp_name_node.css("role>roleTerm").collect(&:content).any? { |role| CORPORATE_DEPARTMENT_ROLES.include?(role.downcase) })
          name_part = corp_name_node.at_css("namePart").text
          if(name_part.include?(". "))
            name_part_split = name_part.split(". ")
            organizations.push(name_part_split[0].strip)
            departments.push(name_part_split[1].strip)
            originator_department = name_part_split[1].strip
          end
        end
        if corp_name_node.css("role>roleTerm").collect(&:content).any? { |role| CORPORATE_AUTHOR_ROLES.include?(role.downcase) }
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
      add_field.call("pub_date_facet", mods.at_css(">originInfo>dateIssued"))

      mods.css("genre").each do |genre_node|
        add_field.call("genre_facet", genre_node)
        add_field.call("genre_search", genre_node)
      end

      add_field.call("abstract", mods.at_css("abstract"))

      mods.css("subject").each do |subject_node|
        attri = subject_node.attributes
        if attri.count.zero? || (attri['authority'] && attri['authority'].value == 'fast')
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

      if related_host = mods.at_css("relatedItem[@type='host']:not([displayLabel=Project])")
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

        add_field.call("book_author", get_fullname(related_host.at_css("name")))

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
        type = RESOURCE_TYPES[type] if (RESOURCE_TYPES.has_key?(type))
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

      solr_doc
    end

    def index_fulltext
  # if(do_fulltext) ## ===   fulltext_processing === does not work correctly if move it to separate method
  #
      # Rails.logger.debug "======= fulltext started === "
  #
       # list_members.each_with_index do |member, i|
  #
          # begin
  #
          # resource_file = Rails.application.config.fedora['url'] + "/objects/#{member.pid}/datastreams/CONTENT/content"
          # Rails.logger.debug "======= fulltext resource_file === " + resource_file
  #
          # text_extract_command = "java -jar " + Rails.application.secrets.full_text_indexing['text_extractor_jar_file'] + " -t #{resource_file}"
          # Rails.logger.debug "======= fulltext text_extract_command === " + text_extract_command
  #
          # tika_result = `#{text_extract_command}`
          # add_field.call("ac.fulltext_#{i}", tika_result)
  #
          # rescue Exception => e
            # status = :error
            # error_message += e.message
            # Rails.logger.debug "======= fulltext indexing error: " + e.message
          # end
  #
           # Rails.logger.debug "======= fulltext finished === "
        # end
    # end   ##========================  fulltext_processing end ======================== #
    end

    def recordInfoIndexing(mods, add_field)

      if(record_content_source = mods.at_css("recordInfo>recordContentSource"))
        add_field.call("record_content_source", record_content_source)
      end

      if(record_creation_date = mods.at_css("recordInfo>recordCreationDate"))
        record_creation_date = DateTime.parse(record_creation_date.text.gsub("UTC", "").strip)
        add_field.call("record_creation_date", record_creation_date.strftime("%Y-%m-%dT%H:%M:%SZ"))

        Rails.logger.info "====== record_creation_date: " + record_creation_date.strftime("%Y-%m-%dT%H:%M:%SZ")

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

        logger.info "====== record_creation_date: " + record_change_date.strftime("%Y-%m-%dT%H:%M:%SZ")
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
      roles = []
      mods.css("role > roleTerm").each do |role|
        if(!role.nil? && role.text.length != 0)
          roles << role.text.downcase
        end
      end
      roles
    end

    # Returns persistent uri which could be a doi(with no prefix),
    # doi(with prefix) or a handle.
    def persistent_uri(mods, add_field)
      field = if (uri = mods.at_css("identifier[@type='DOI']")) && !uri.text.blank?
                uri
              elsif (uri = mods.at_css("identifier[@type='CDRS doi']")) && !uri.text.blank?
                uri
              else
                mods.at_css("identifier[@type='hdl']").text
              end
      add_field.call('handle', field)
    end

    def identifierIndexing(mods, add_field)
      if(isbn = mods.at_css("identifier[@type='isbn']"))
        if(!isbn.nil? && isbn.text.length != 0)
          add_field.call("isbn", isbn)
        end
      end

      # Publisher DOI
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
      if(free_to_read_start_date = mods.at_css("free_to_read"))
        if(free_to_read_start_date = mods.at_css("free_to_read")['start_date'])
          if(!free_to_read_start_date.nil? && free_to_read_start_date.length != 0)
             add_field.call("free_to_read_start_date", free_to_read_start_date)
          end
        end
      end
    end

    def degree_indexing(mods, add_field)
      if degree = mods.at_css("> extension > degree")
        if (name = degree.at_css("name")) && !name.text.blank?
          add_field.call("degree_name_ssim", name)
        end

        if (grantor = degree.at_css("grantor")) && !name.text.blank?
          add_field.call("degree_grantor_ssim", grantor)
        end

        if (level = degree.at_css("level")) && !level.text.blank?
          add_field.call("degree_level_ssim", level)
        end
      end
    end

    # If there a namePart element with no type attribute use that name, otherwise
    # look for a first and last name and combine them.
    # TODO: This logic can be simplified when we completely transition to Hyacinth.
    def get_fullname(node)
      return nil if node.nil?
      if name = node.at_css('namePart:not([type])')
        name.content
      else
        (node.css("namePart[@type='family']").collect(&:content) | node.css("namePart[@type='given']").collect(&:content)).join(', ')
      end
    end
  end
end
