module AcademicCommons
  module Indexable
    AUTHOR_ROLES = %w(author creator speaker moderator interviewee interviewer contributor).freeze
    ADVISOR_ROLES = ['thesis advisor'].freeze
    CORPORATE_AUTHOR_ROLES = ['author'].freeze
    CORPORATE_DEPARTMENT_ROLES = ['originator'].freeze
    RESOURCE_TYPES = {
      'text'                        => 'Text',
      'notated music'               => 'Notated music',
      'cartographic'                => 'Image',
      'still image'                 => 'Image',
      'sound recording-musical'     => 'Audio',
      'sound recording-nonmusical'  => 'Audio',
      'moving image'                => 'Video',
      'three dimensional object'    => 'Other',
      'software, multimedia'        => 'Software',
      'mixed material'              => 'Mixed media'
    }.freeze
    DEGREE_LABELS = {
      '0' => 'Bachelor\'s',
      '1' => 'Master\'s',
      '2' => 'Doctoral'
    }.freeze
    # this is documentary, and should go away when this module is a concern
    REQUIRED_METHODS = [:belongs_to, :descMetadata_content]

    # Keeping track of multivalued fields until we move over to using dynamic
    # field names. Once we make the switch this can be reduced.
    MULTIVALUED_FIELDS = %w(
      member_of internal_h author_uni advisor_uni author_search advisor_search
      genre_search keyword_search subject_display subject_search notes
      book_author geographic_area_display geographic_area_search role
      affiliation_department type_of_resource_mods author_info thesis_advisor
      \w+_ssm \w+_ssim \w+_facet \w+_s \w+_t
    ).freeze

    def index_descMetadata(solr_doc={})
      raise 'called index_descMetadata twice' if (@index_descMetadata ? (@index_descMetadata += 1) : (@index_descMetadata = 1)) > 1

      meta = descMetadata_datastream
      raise "descMetadata COULD NOT be found for #{self.pid}.\nSolr doc: #{solr_doc.inspect}" unless meta

      solr_doc['described_by_ssim'] = ["info:fedora/#{meta.pid}/#{meta.dsid}"]
      document = Nokogiri::XML(meta.content).remove_namespaces!
      mods = document.at_css('mods')

      collections = self.belongs_to
      normalize_space = lambda { |s| s.to_s.strip.gsub(/\s{2,}/,' ') }

      # Adds value to solr doc hash, if there is a value present.
      # Accepts String of Nokogiri::XML::Element as value
      add_field = lambda { |name, value|
        return if value.nil?
        value = value.content if value.kind_of?(Nokogiri::XML::Element)
        value = value.strip
        return if value.blank?

        if multivalued?(name)
          solr_doc[name] = [] unless solr_doc[name]
          solr_doc[name] << value
        else
          solr_doc[name] = value
        end
      }

      organizations = []
      departments = []
      originator_department = ''
      # baseline blacklight fields: id is the unique identifier, format determines by default, what partials get called
      #TODO: Make sure access is indifferent
      add_field.call('id', self.pid) unless (solr_doc['id'] || solr_doc[:id])
      add_field.call('internal_h',  collections.first.to_s + '/')
      add_field.call('pid', self.pid) unless (solr_doc['pid'] || solr_doc[:pid])
      collections.each do |collection|
        add_field.call('member_of', collection)
      end

      recordInfoIndexing(mods, add_field)
      locationIndexing(mods, add_field)
      languageIndexing(mods, add_field)
      originInfoIndexing(mods, add_field)
      roleIndexing(mods, add_field)
      persistent_uri(mods, add_field)
      identifierIndexing(mods, add_field)
      locationUrlIndexing(mods, add_field)
      embargo_release_date_indexing(mods, add_field)
      degree_indexing(mods, add_field)
      access_condition(mods, add_field)

      title = mods.css('>titleInfo>title')
      related_titles = mods.css('relatedItem[@type=\'host\']:not([displayLabel=Project])>titleInfo').css('>nonSort,title')

      title_search = normalize_space.call((title + related_titles).collect(&:content).join(' '))

      add_field.call('title_display', title.first.text)
      add_field.call('title_search', title_search)

      all_author_names = []
      mods.css('>name[@type=\'personal\']').each do |name_node|

        fullname = get_fullname(name_node)
        note_org = false

        if name_node.css('role>roleTerm').collect(&:content).any? { |role| AUTHOR_ROLES.include?(role.downcase) }
          note_org = true
          all_author_names << fullname
          if(!name_node['ID'].nil?)
            add_field.call('author_uni', name_node['ID'])
          end

          author_affiliations = []

          name_node.css('affiliation').each do |affiliation_node|
            author_affiliations.push(affiliation_node.text)
          end

          uni = name_node['ID'] == nil ? '' : name_node['ID']

          add_field.call('author_info', fullname + ' : ' + uni + ' : ' + author_affiliations.join('; '))

          add_field.call('author_search', fullname.downcase)
          add_field.call('author_facet', fullname)

        elsif name_node.css('role>roleTerm').collect(&:content).any? { |role| ADVISOR_ROLES.include?(role.downcase) }
          note_org = true
          first_role = name_node.at_css('role>roleTerm').text
          add_field.call(first_role.downcase.gsub(/\s/, '_'), fullname)

          add_field.call('advisor_uni', name_node['ID'])
          add_field.call('advisor_search', fullname.downcase)
        end

        if (note_org == true)
          name_node.css('affiliation').each do |affiliation_node|
            affiliation_text = affiliation_node.text
            if(affiliation_text.include?('. '))
              affiliation_split = affiliation_text.split('. ')
              organizations.push(affiliation_split[0].strip)
              departments.push(affiliation_split[1].strip)
            end
          end
        end
      end

      mods.css('>name[@type=\'corporate\']').each do |corp_name_node|
        if((!corp_name_node['ID'].nil? && corp_name_node['ID'].include?('originator')) || corp_name_node.css('role>roleTerm').collect(&:content).any? { |role| CORPORATE_DEPARTMENT_ROLES.include?(role.downcase) })
          name_part = corp_name_node.at_css('namePart').text
          if(name_part.include?('. '))
            name_part_split = name_part.split('. ')
            organizations.push(name_part_split[0].strip)
            departments.push(name_part_split[1].strip)
            originator_department = name_part_split[1].strip
          end
        end
        if corp_name_node.css('role>roleTerm').collect(&:content).any? { |role| CORPORATE_AUTHOR_ROLES.include?(role.downcase) }
          display_form = corp_name_node.at_css('displayForm')
          if(!display_form.nil?)
            fullname = display_form.text
          else
            fullname = corp_name_node.at_css('namePart').text
          end
          all_author_names << fullname
          add_field.call('author_search', fullname.downcase)
          add_field.call('author_facet', fullname)
        end
      end

      add_field.call('author_display',all_author_names.join('; '))
      add_field.call('pub_date_facet', mods.at_css('>originInfo>dateIssued'))

      mods.css('genre').each do |genre_node|
        add_field.call('genre_facet', genre_node)
        add_field.call('genre_search', genre_node)
      end

      add_field.call('abstract', mods.at_css('abstract'))

      mods.css('subject').each do |subject_node|
        attri = subject_node.attributes
        if attri.count.zero? || (attri['authority'] && attri['authority'].value == 'fast')
          subject_node.css('topic,title,namePart').each do |topic_node|
            add_field.call('keyword_search', topic_node.content.downcase)
            add_field.call('subject_facet', topic_node)
            add_field.call('subject_search', topic_node)
          end
        end
      end

      add_field.call('originator_department', originator_department)
      add_field.call('table_of_contents', mods.at_css('tableOfContents'))

      mods.css('note').each { |note| add_field.call('notes', note) }

      if related_host = mods.at_css('relatedItem[@type=\'host\']:not([displayLabel=Project])')
        book_journal_title = related_host.at_css('titleInfo>title')

        if book_journal_title
          book_journal_subtitle = mods.at_css('name>titleInfo>subTitle')
          book_journal_title = book_journal_title.content + ': ' + book_journal_subtitle.content.to_s if book_journal_subtitle
        end

        add_field.call('volume', related_host.at_css('part>detail[@type=\'volume\']>number'))
        add_field.call('issue', related_host.at_css('part>detail[@type=\'issue\']>number'))
        add_field.call('start_page', related_host.at_css('part > extent[@unit=\'page\'] > start'))
        add_field.call('end_page', related_host.at_css('part > extent[@unit=\'page\'] > end'))
        add_field.call('date', related_host.at_css('part > date'))

        add_field.call('book_journal_title', book_journal_title)

        related_host.css('name').each do |book_author|
          add_field.call('book_author', get_fullname(book_author))
        end
      end

      if(related_series = mods.at_css('relatedItem[@type=\'series\']'))
        if(related_series.has_attribute?('ID'))
          add_field.call('series_facet', related_series.at_css('titleInfo>title'))
        else
          add_field.call('non_cu_series_facet', related_series.at_css('titleInfo>title'))
        end
        add_field.call('part_number', related_series.at_css('titleInfo>partNumber'))
      end

      mods.css('physicalDescription>internetMediaType').each { |mt| add_field.call('media_type_facet', mt) }

      mods.css('typeOfResource').each { |tr|
        add_field.call('type_of_resource_mods', tr)
        type = tr.text
        type = RESOURCE_TYPES[type] if (RESOURCE_TYPES.has_key?(type))
        add_field.call('type_of_resource_facet', type)
      }

      mods.css('subject>geographic').each do |geo|
        add_field.call('geographic_area_display', geo)
        add_field.call('geographic_area_search', geo)
      end

      # This is just a placeholder, reminding us that we need to implement citations in some way
      # add_field.call('export_as_mla_citation_txt','')

      if(organizations.count > 0)
        organizations = organizations.uniq
        organizations.each do |organization|
          add_field.call('organization_facet', organization)
        end
      end

      if(departments.count > 0)
        departments = departments.uniq
        departments.each do |department|
          add_field.call('department_facet', department.to_s.sub(', Department of', '').strip)
        end
      end

      solr_doc
    end

    def recordInfoIndexing(mods, add_field)
      add_field.call('record_content_source', mods.at_css('recordInfo>recordContentSource'))

      if(record_creation_date = mods.at_css('recordInfo>recordCreationDate'))
        record_creation_date = DateTime.parse(record_creation_date.text.gsub('UTC', '').strip)
        add_field.call('record_creation_date', record_creation_date.strftime('%Y-%m-%dT%H:%M:%SZ'))

        Rails.logger.info '====== record_creation_date: ' + record_creation_date.strftime('%Y-%m-%dT%H:%M:%SZ')
      end

      if(record_change_date = mods.at_css('recordInfo>recordChangeDate'))
        record_change_date = DateTime.parse(record_change_date.text.gsub('UTC', '').strip)
        add_field.call('record_change_date', record_change_date.strftime('%Y-%m-%dT%H:%M:%SZ'))
      end

      add_field.call('record_identifier', mods.at_css('recordInfo>recordIdentifier'))
      add_field.call('record_language_of_catalog', mods.at_css('recordInfo>languageOfCataloging>languageTerm'))

      if(record_creation_date.nil? && !record_change_date.nil?)
        add_field.call('record_creation_date', record_change_date.strftime('%Y-%m-%dT%H:%M:%SZ'))

        logger.info '====== record_creation_date: ' + record_change_date.strftime('%Y-%m-%dT%H:%M:%SZ')
      end
    end

    def locationIndexing(mods, add_field)
      add_field.call('physical_location', mods.at_css('location>physicalLocation'))
    end

    def languageIndexing(mods, add_field)
      add_field.call('language', mods.at_css('language>languageTerm'))
    end

    def originInfoIndexing(mods, add_field)
      add_field.call('publisher', mods.at_css('originInfo > publisher'))
      add_field.call('publisher_location', mods.at_css('originInfo>place>placeTerm'))
      add_field.call('date_issued', mods.at_css('originInfo>dateIssued'))
      add_field.call('edition', mods.at_css('originInfo>edition'))
    end

    def roleIndexing(mods, add_field)
      mods.css('>name>role>roleTerm').each do |role|
        if(!role.nil? && role.text.length != 0)
          add_field.call('role', role.text.downcase)
        end
      end
    end

    # Returns persistent uri which could be a doi(with no prefix),
    # doi(with prefix) or a handle.
    def persistent_uri(mods, add_field)
      field = if (uri = mods.at_css('identifier[@type=\'DOI\']')) && !uri.text.blank?
                uri
              elsif (uri = mods.at_css('identifier[@type=\'CDRS doi\']')) && !uri.text.blank?
                uri
              else
                mods.at_css('identifier[@type=\'hdl\']').text
              end
      add_field.call('handle', field)
      add_field.call('cul_doi_ssi', field)
    end

    def identifierIndexing(mods, add_field)
      add_field.call('isbn', mods.at_css('identifier[@type=\'isbn\']'))
      add_field.call('doi', mods.at_css('identifier[@type=\'doi\']')) # Publisher DOI
      add_field.call('uri', mods.at_css('identifier[@type=\'uri\']'))
      add_field.call('issn', mods.at_css('identifier[@type=\'issn\']'))
    end

    def locationUrlIndexing(mods, add_field)
      add_field.call('url', mods.at_css('location > url'))
    end

    def embargo_release_date_indexing(mods, add_field)
      if(free_to_read_start_date = mods.at_css('free_to_read'))
        if(free_to_read_start_date = mods.at_css('free_to_read')['start_date'])
          if(!free_to_read_start_date.nil? && free_to_read_start_date.length != 0)
             # Date and string field available, eventually the string field can be removed.
             add_field.call('free_to_read_start_date', free_to_read_start_date)

             free_to_read_time_formatted = Time.zone.local(*free_to_read_start_date.split('-')).utc.strftime('%FT%TZ')
             add_field.call('free_to_read_start_date_dtsi', free_to_read_time_formatted)
          end
        end
      end
    end

    def degree_indexing(mods, add_field)
      if degree = mods.at_css('> extension > degree')
        add_field.call('degree_name_ssim', degree.at_css('name'))
        add_field.call('degree_grantor_ssim',  degree.at_css('grantor'))

        level = degree.at_css('level').text
        add_field.call('degree_level_ssim', level)
        add_field.call('degree_level_name_ssim', DEGREE_LABELS[level]) if DEGREE_LABELS.key?(level)
      end
    end

    def access_condition(mods, add_field)
      if restriction = mods.at_css('> accessCondition[@type=\'restriction on access\']')
        add_field.call('restriction_on_access_ss', restriction.text)
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
        (node.css('namePart[@type=\'family\']').collect(&:content) | node.css('namePart[@type=\'given\']').collect(&:content)).join(', ')
      end
    end

    def multivalued?(field)
      !MULTIVALUED_FIELDS.map { |f| /^#{f}$/.match field }.compact.empty?
    end
  end
end
