# rubocop:disable Metrics/ModuleLength, Metrics/MethodLength
module AcademicCommons
  module DescMetadata
    extend ActiveSupport::Concern

    AUTHOR_ROLES = %w[author creator speaker moderator interviewee interviewer contributor].freeze
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
    
    GENRE_TYPES = {
      'learning object'             => 'Learning Objects'
    }.freeze
    
    DEGREE_LABELS = {
      '0' => 'Bachelor\'s',
      '1' => 'Master\'s',
      '2' => 'Doctoral'
    }.freeze
    # Related item types should be displayed in this order.
    ORDERED_RELATED_ITEM_TYPES = [
      'Continues',
      'IsContinuedBy',
      'isIdenticalTo',
      'isVersionOf',
      'isNewVersionOf',
      'isPreprintOf',
      'isPreviousVersionOf',
      'isSupplementedBy',
      'isSupplementTo',
      'translation',
      'translationOf',
      'referencedBy',
      'references',
      'reviewOf',
      'IsCompiledBy',
      'IsDerivedFrom',
      'hasPart',
      'partOf',
      'IsSourceOf'
    ].freeze

    # Keeping track of multivalued fields.
    MULTIVALUED_FIELDS = %w[\w+_ssm \w+_ssim \w+_q suggest].freeze

    # ** Please read the following documentation before changing any of the fields ***

    # As a minimum we index all fields using dynamic field names based on the
    # needs of that particular field. Most facet-able fields have the prefix _ssim.
    # Please see the configuration for more details.

    # In some cases fields are indexed multiple times:
    #   1. Fields with `_q` suffix are indexed for better querying results (by using
    #      different tokenizers) and are copied into the general query search field. Some
    #      of these fields are also used to specify weighting when returning search
    #      results. Please consult schema.xml and solrconfig.xml before removing any of these fields.
    #   2. `suggest` field is used to populate the suggest handler used by the
    #      autocomplete dropdown.
    #   3. Fields with a `_sort` suffix are used for alphanumeric sorting. Filters
    #      are applied to the field that lowercase the content and remove any
    #      non-alphanumeric characters.
    def index_descmetadata(solr_doc = {})
      raise 'called index_descMetadata twice' if (@index_descmetadata ? (@index_descmetadata += 1) : (@index_descmetadata = 1)) > 1

      meta = descmetadata_datastream
      raise "descMetadata COULD NOT be found for #{pid}.\nSolr doc: #{solr_doc.inspect}" unless meta

      solr_doc['described_by_ssim'] = ["info:fedora/#{meta.pid}/#{meta.dsid}"]
      document = Nokogiri::XML(meta.content).remove_namespaces!
      mods = document.at_css('mods')

      # Adds value to solr doc hash, if there is a value present.
      # Accepts String of Nokogiri::XML::Element as value
      add_field = lambda { |name, value|
        return if value.nil?
        value = value.content if value.is_a?(Nokogiri::XML::Element) || value.is_a?(Nokogiri::XML::Attr)
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

      # Using DOI as document id, getting doi from fedora object.
      doi = solr_doc.fetch('doi_ssim', nil)
      raise StandardError, 'missing doi from fedora object' if doi.blank?
      doi.gsub!('doi:', '')
      add_field.call 'cul_doi_ssi', doi
      add_field.call 'id',          doi

      # Adding fedora3 pid to document. Used for relating objects to each other.
      add_field.call('fedora3_uri_ssi', "info:fedora/#{pid}")
      add_field.call('fedora3_pid_ssi', pid)

      add_field.call 'related_url_ssi', mods.at_css('location > url')

      # TITLE
      # Note: We are intentionally including the non-sort portion in the title_sort field to
      # preserve existing app behavior.  This is what the AC app owners want.
      title = [mods.at_css('> titleInfo > nonSort'), mods.at_css('> titleInfo > title')].compact.join(' ')
      add_field.call 'title_ssi',  title
      add_field.call 'title_sort', title
      add_field.call 'title_q',    title
      add_field.call 'suggest',    title

      # PERSONAL NAMES
      all_author_names = []
      mods.css('> name[@type=\'personal\']').each do |name_node|
        fullname = name_node.at_css('namePart:not([type])').content

        if name_node.css('role > roleTerm').collect(&:content).any? { |role| AUTHOR_ROLES.include?(role.downcase) }
          all_author_names << fullname

          add_field.call 'author_uni_ssim', name_node.attribute('ID')
          add_field.call 'author_uni_q',    name_node.attribute('ID')

          add_field.call 'author_ssim', fullname
          add_field.call 'author_q',    fullname
          add_field.call 'suggest',     fullname
          add_field.call 'suggest',     fullname.split(/,\s*/).reverse.join(' ')

        elsif name_node.css('role>roleTerm').collect(&:content).any? { |role| ADVISOR_ROLES.include?(role.downcase) }
          first_role = name_node.at_css('role>roleTerm').text
          add_field.call first_role.downcase.gsub(/\s/, '_') + '_ssim', fullname
          add_field.call first_role.downcase.gsub(/\s/, '_') + '_q',    fullname
          add_field.call 'suggest',                                     fullname
          add_field.call 'suggest',                                     fullname.split(/,\s*/).reverse.join(' ')

          add_field.call 'advisor_uni_ssim', name_node.attribute('ID')
          add_field.call 'advisor_uni_q',    name_node.attribute('ID')
        end
      end

      # CORPORATE NAMES
      mods.css('> name[@type=\'corporate\']').each do |corp_name_node|
        name_part = corp_name_node.at_css('namePart').text
        roles = corp_name_node.css('role > roleTerm').collect(&:content).map(&:downcase)
        if roles.any? { |role| CORPORATE_DEPARTMENT_ROLES.include?(role) } && name_part.include?('. ')
          name_part_split = name_part.split('. ')
          organizations.push(name_part_split[0].strip)
          departments.push(name_part_split[1].strip)
        end

        next unless roles.any? { |role| CORPORATE_AUTHOR_ROLES.include?(role) }
        all_author_names << name_part
        add_field.call 'author_ssim', name_part
        add_field.call 'author_q',    name_part
        add_field.call 'suggest',     name_part
      end

      # DATE AND EDITION
      add_field.call 'pub_date_isi', mods.at_css('> originInfo > dateIssued')
      add_field.call 'edition_ssi',  mods.at_css('> originInfo > edition')

      # PUBLISHER
      add_field.call 'publisher_ssi', mods.at_css('> originInfo > publisher')
      add_field.call 'publisher_q',   mods.at_css('> originInfo > publisher')

      add_field.call 'publisher_location_ssi', mods.at_css('originInfo > place > placeTerm')

      mods.css('genre').each do |genre_node|
        add_field.call 'genre_ssim',  GENRE_TYPES.fetch(genre_node.text, genre_node.content&.titlecase)
        add_field.call 'genre_q',     GENRE_TYPES.fetch(genre_node.text, genre_node.content&.titlecase)
      end

      add_field.call 'abstract_ssi', mods.at_css('> abstract')
      add_field.call 'abstract_q',   mods.at_css('> abstract')

      mods.css('> language > languageTerm').each { |language_node| add_field.call 'language_ssim', language_node }

      # SUBJECT
      mods.css('> subject').each do |subject_node|
        attri = subject_node.attributes
        next unless attri.count.zero? || (attri['authority'])
        subject_node.css('topic,title,namePart').each do |topic_node|
          add_field.call 'subject_ssim', topic_node
          add_field.call 'subject_q',    topic_node
          add_field.call 'suggest',      topic_node
        end
      end

      # GEOGRAPHIC SUBJECT
      mods.css('> subject > geographic').each do |geo|
        add_field.call 'geographic_area_ssim', geo
        add_field.call 'geographic_area_q',    geo
        add_field.call 'suggest',              geo
      end

      mods.css('> note').each do |note|
        add_field.call 'notes_ssim', note
        add_field.call 'notes_q',    note
      end

      # PARENT PUBLICATION
      if (related_host = mods.at_css('> relatedItem[@type=\'host\']:not([displayLabel=Project])'))
        book_journal_title = related_host.at_css('titleInfo>title')

        if book_journal_title
          book_journal_subtitle = mods.at_css('name>titleInfo>subTitle')
          book_journal_title = book_journal_title.content + ': ' + book_journal_subtitle.content.to_s if book_journal_subtitle
        end

        add_field.call 'volume_ssi',         related_host.at_css('part > detail[@type=\'volume\']>number')
        add_field.call 'issue_ssi',          related_host.at_css('part > detail[@type=\'issue\']>number')
        add_field.call 'start_page_ssi',     related_host.at_css('part > extent[@unit=\'page\'] > start')
        add_field.call 'end_page_ssi',       related_host.at_css('part > extent[@unit=\'page\'] > end')
        add_field.call 'date_ssi',           related_host.at_css('part > date')
        add_field.call 'publisher_doi_ssi',  related_host.at_css('identifier[@type=\'doi\']')
        add_field.call 'uri_ssi',            related_host.at_css('identifier[@type=\'uri\']')
        add_field.call 'host_publisher_ssi', related_host.at_css('originInfo > publisher')
        add_field.call 'host_publisher_q',   related_host.at_css('originInfo > publisher')

        add_field.call 'book_journal_title_ssi', book_journal_title
        add_field.call 'book_journal_title_q',   book_journal_title

        is_partner_journal = related_host.attribute('ID').to_s == 'partnerJournal'
        add_field.call 'partner_journal_ssi', book_journal_title if is_partner_journal

        related_host.css('name').each do |book_author|
          add_field.call 'book_author_ssim', book_author.at_css('namePart:not([type])')
          add_field.call 'book_author_q',    book_author.at_css('namePart:not([type])')
          add_field.call 'suggest',          book_author.at_css('namePart:not([type])')
          add_field.call 'suggest',          book_author.at_css('namePart:not([type])').content.split(/,\s*/).reverse.join(' ')
        end
      end

      # SERIES, both cul and non-cul
      mods.css('> relatedItem[@type=\'series\']').each do |related_series|
        if related_series.has_attribute?('ID')
          add_field.call 'series_ssim', related_series.at_css('titleInfo>title')
          add_field.call 'series_q',    related_series.at_css('titleInfo>title')
          add_field.call 'suggest',     related_series.at_css('titleInfo>title')

          part_number = related_series.at_css('titleInfo>partNumber')
          add_field.call(
            'series_part_number_ssim',
            part_number ? part_number.content : 'NONE'
          )
        else
          add_field.call('non_cu_series_ssim', related_series.at_css('titleInfo>title'))
          add_field.call('non_cu_series_q',    related_series.at_css('titleInfo>title'))
          add_field.call('suggest',            related_series.at_css('titleInfo>title'))

          part_number = related_series.at_css('titleInfo>partNumber')
          add_field.call(
            'non_cu_series_part_number_ssim',
            part_number ? part_number.content : 'NONE'
          )
        end
      end

      # RELATED ITEM
      #
      # Creates a json structure that is an Array of Hashes. Each hash is a related items entry.
      related_items_selector = '//relatedItem[' + ORDERED_RELATED_ITEM_TYPES.map { |type| "@otherType='#{type}'" }.join(' or ') + ']'
      related_items = mods.xpath(related_items_selector).map do |related_item|
        identifier = related_item.at_css('> identifier') # There should only be one identifier

        {
          relation_type: related_item.attribute('otherType')&.content || related_item.attribute('type')&.content, # Attribute
          title: related_item.at_css('> titleInfo > title')&.content,
          identifier: {
            type: identifier.attribute('type')&.content,
            value: identifier&.content
          }
        }
      end
      solr_doc['related_items_ss'] = related_items.to_json

      mods.css('> physicalDescription > internetMediaType').each { |mt| add_field.call('media_type_ssim', mt) }

      mods.css('> typeOfResource').each do |tr|
        add_field.call 'type_of_resource_mods_ssim', tr
        add_field.call 'type_of_resource_ssim',      RESOURCE_TYPES.fetch(tr.text, nil)
      end

      organizations.uniq.each do |org|
        add_field.call('organization_ssim', org)
        add_field.call('organization_q', org)
      end

      departments = departments.uniq.map { |d| d.to_s.sub(', Department of', '') }
      departments.each do |dep|
        add_field.call 'department_ssim', dep
        add_field.call 'department_q',    dep
        add_field.call 'suggest',         dep
      end

      # EMBARGO RELEASE DATE
      if (free_to_read = mods.at_css('> extension > free_to_read'))
        start_date = free_to_read.attribute('start_date').to_s
        if start_date.present?
          add_field.call 'free_to_read_start_date_ssi',  start_date
          add_field.call 'free_to_read_start_date_dtsi', Time.zone.local(*start_date.split('-')).utc.iso8601
        end
      end

      # DEGREE INFO
      if (degree = mods.at_css('> extension > degree'))
        add_field.call 'degree_name_ssim',         degree.at_css('name')
        add_field.call 'degree_grantor_ssim',      degree.at_css('grantor')
        add_field.call 'degree_discipline_ssim',   degree.at_css('discipline')

        level = degree.at_css('level').text
        add_field.call('degree_level_ssim', level)
        add_field.call('degree_level_name_ssim', DEGREE_LABELS.fetch(level, nil))
      end

      # RECORD INFO
      add_field.call 'record_creation_dtsi', mods.at_css('> recordInfo > recordCreationDate')
      add_field.call 'record_change_dtsi',   mods.at_css('> recordInfo > recordChangeDate')

      # ACCESS CONDITION
      add_field.call('restriction_on_access_ss', mods.at_css('> accessCondition[@type=\'restriction on access\']'))

      # USE AND REPRODUCTION
      mods.css('> accessCondition[@type=\'use and reproduction\']').each do |r|
        add_field.call 'use_and_reproduction_label_ssim', r
        add_field.call 'use_and_reproduction_uri_ssim',   r.attribute('href')
      end

      solr_doc
    end

    def multivalued?(field)
      !MULTIVALUED_FIELDS.map { |f| /^#{f}$/.match field }.compact.empty?
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/ModuleLength
