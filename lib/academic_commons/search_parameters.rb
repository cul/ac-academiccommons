module AcademicCommons
  class SearchParameters
    MAX_ROWS = 100_000

    SEARCH_TYPES = {
      keyword: {},
      title: { 'spellcheck.dictionary': 'title', qf: '${title_qf}', pf: '${title_pf}' },
      subject: { 'spellcheck.dictionary': 'subject', qf: '${subject_qf}', pf: '${subject_pf}' }
    }.freeze

    attr_reader :parameters

    def initialize
      @parameters = {
        qt: 'search',
        fq: [],
        rows: MAX_ROWS
      }
    end

    def q(q)
      @parameters[:q] = q
      self
    end

    def filter(key, value)
      @parameters[:fq] << if value.start_with?('(', '[') && value.end_with?(']', ')')
                            "#{key}:#{value}"
                          else
                            "#{key}:\"#{value}\""
                          end

      self
    end

    def sort_by(sort)
      @parameters[:sort] = sort
      self
    end

    def rows(rows)
      @parameters[:rows] = rows
      self
    end

    def start(start)
      @parameters[:start] = start
      self
    end

    # Only returns fields specified, the default behavior is to return all the
    # fields. Modifies the :fl solr parameter. Use carefully! This limits the
    # fields returned and could lead to unintended results.
    def field_list(*fields)
      @parameters[:fl] = Array.wrap(fields).join(',')
      self
    end

    def id(id)
      filter('id', id)
      self
    end

    def aggregators_only
      filter('has_model_ssim', ContentAggregator.to_class_uri)
      self
    end

    # USE CAREFULLY!!
    #
    # This method does not filter out embargoed assets. Assets are embargoed at the item level and
    # therefore the embargo status of an item should be checked before using this method.
    def assets_for(fedora3_pid)
      raise ArgumentError, 'Fedora 3 pid required' if fedora3_pid.blank?

      filter('cul_member_of_ssim', "info:fedora/#{fedora3_pid}")
      filter('object_state_ssi', 'A')
      rows(MAX_ROWS)
      without_facets
      self
    end

    # USE CAREFULLY!!
    #
    # Returns aggregators with a search results for its assets in a field named 'assets'.
    #
    # This method does not filter out embargoed assets. Assets are embargoed at the item level and
    # therefore the embargo status of an item should be checked before using this data.
    def aggregators_with_assets
      aggregators_only

      # Adding subquery for assets
      field_list('*', 'assets:[subquery]')
      @parameters[:'assets.q'] = '{!terms f=cul_member_of_ssim v=$row.fedora3_uri_ssi}'
      @parameters[:'assets.rows'] = MAX_ROWS
      self
    end

    def embargoed_only
      filter('object_state_ssi', 'A')
      @parameters[:fq] << 'free_to_read_start_date_dtsi:[NOW+1DAYS TO *]'
    end

    def member_of(pid); end

    def fedora3_pid(pid); end

    def without_facets
      @parameters[:facet] = false
      self
    end

    def facet_by(*fields)
      @parameters[:facet] = true
      @parameters[:'facet.field'] = fields
      self
    end

    def facet_limit(limit)
      @parameters[:'facet.limit'] = limit
      self
    end

    def search_type(type)
      raise ArgumentError, 'search type not valid' unless SEARCH_TYPES.key?(type)
      @parameters.merge!(SEARCH_TYPES[type])
      self
    end

    def to_h
      parameters
    end
  end
end
