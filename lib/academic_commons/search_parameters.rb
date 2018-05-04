module AcademicCommons
  class SearchParameters
    attr_reader :parameters

    def initialize
      @parameters = {
        qt: 'search',
        fq: []
      }
    end

    def q(q)
      @parameters[:q] = q
      self
    end

    def id(id)
      filter('id', id)
    end

    def filter(key, value)
      @parameters[:fq] << "#{key}:\"#{value}\""
      self
    end

    def assets_only; end

    def aggregators_only
      filter('has_model_ssim', ContentAggregator.to_class_uri)
      self
    end

    def rows(rows)
      @parameters[:rows] = rows
      self
    end

    def member_of(pid); end

    def fedora3_pid(pid); end

    def facet_by(*fields)
      @parameters[:facet] = true
      @parameters[:'facet.field'] = fields
      self
    end

    def facet_limit(limit)
      @parameters[:'facet.limit'] = limit
      self
    end

    def to_h
      parameters
    end
  end
end
