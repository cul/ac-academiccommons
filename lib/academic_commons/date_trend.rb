module AcademicCommons
  class DateTrend
    def initialize(date_field = 'record_creation_dtsi', af_model = nil)
      @date_field = date_field.to_s
      if af_model
        @fq = ["has_model_ssim:\"#{af_model.to_class_uri}\""]
      else
        @fq = []
      end
    end

    # get a facet range by months for the last year
    # facet on active fedora model to minimize response size
    # include no documents
    def search_params
      @solr_parameters ||= {
        rows: 0,
        fq: @fq,
        :"f.#{@date_field}.facet.range.gap" => '+1MONTH',
        :"f.#{@date_field}.facet.range.start" => 'NOW-1YEAR',
        :"f.#{@date_field}.facet.range.end" => 'NOW',
        :"f.#{@date_field}.facet.sort" => 'index',
        :"facet.range" => @date_field,
        :"facet.field" => 'active_fedora_model_ssi'
      }
    end

    def counts
      @counts ||= begin
        last_month = last_month = (Time.now - 1.month).getutc.to_s[0..6]
        repository = Blacklight.default_index.connection
        solr_results = repository.get('select', params: search_params)
        results = Hash.new(0)
        results[:total] = solr_results['response']['numFound']
        facets = solr_results['facet_counts']
        if facets && facets['facet_ranges'] && facets['facet_ranges'][@date_field.to_s]
          counts = facets['facet_ranges'][@date_field.to_s]['counts']
          results[:last_year] = (0...counts.length/2).inject(0) do |m, ix|
            m + counts[1 + ix * 2]
          end
          if counts.length > 1
            results[:last_month] = counts[-1] if counts[-2].index(last_month)
          end
        end
        results
      end
    end

    def last_month
      counts[:last_month]
    end

    def last_year
      counts[:last_year]
    end

    def total
      counts[:total]
    end
  end
end
