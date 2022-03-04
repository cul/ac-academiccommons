require 'academic_commons'

module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include ApplicationHelper

  delegate :repository, to: :controller

  # Adds handle or doi prefix if necessary. Makes field a clickable link.
  def link_identifier(**options)
    value = options[:value].is_a?(Array) ? options[:value].first : options[:value]
    url = AcademicCommons.identifier_url(value)
    [link_to(url, url)]
  end

  # Combines title and part number for series. Used on item page.
  def combine_title_and_part_number(**options)
    field = options[:field]
    part_number_field = field.gsub('_ssim', '_part_number_ssim')
    part_numbers = options[:document].fetch(part_number_field, [])
    options.fetch(:value, []).zip(part_numbers).map do |title, part_number|
      facet_params = search_state.reset.add_facet_params(field, title)
      value = link_to title, search_action_path(facet_params)

      value.concat(", #{part_number}") unless part_number == 'NONE'
      value
    end
  end

  def date_format(**options)
    options[:value].map do |v|
      # convert to a date time object and then format date
      Time.zone.parse(v).strftime('%B %-d, %Y')
    end
  end

  # transforms related item label information
  def related_item_relation_label(related_item)
    related_item[:relation_type].sub('isNewVersionOf', 'Previous version').sub('isPreviousVersionOf', 'Subsequent version').remove(/^is/).underscore.gsub('_', ' ').upcase_first.concat(':')
  end

  # Wraps spans around each value.
  def wrap_in_spans(**options)
    safe_join(options.fetch(:value, []).map { |v| content_tag(:span, html_escape(v)) })
  end

  # Render values as metatags. Not displayed on the page, but are visible to search engines.
  def metatags(**options)
    itemprop = options.dig(:config, :itemprop)
    safe_join(
      options.fetch(:value, []).map { |v| content_tag(:meta, nil, itemprop: itemprop, content: v) }
    )
  end

  # TODO: Move to a browse controller
  def collect_facet_field_values(facet_field_results)
    results = {}
    facet_field_results.each do |facet_field, facet_counts|
      results[facet_field] = (0...facet_counts.length/2).map do |ix|
        { name: facet_counts[ix * 2], count: facet_counts[1 + ix * 2] }
      end
    end
    results
  end

  # TODO: Move to a browse controller
  def single_facet_values(facet_field)
    query_params = { q: '', rows: '0', 'facet.limit'=> -1, 'facet.field' => facet_field}
    solr_results = repository.search(query_params)
    facet_field_results = solr_results.facet_counts['facet_fields']
    collect_facet_field_values(facet_field_results).fetch(facet_field,[])
  end

  def get_metadata_list(doc)
    #catch any error and return an error message that resources are unavailable
    #this prevents fedora server outages from making ac2 item page inaccessible
    begin
      #TODO: is this side effect on doc necessary?
      doc['object_display'] = [ "#{fedora_config["url"]}" + '/objects/' + doc['id'] + '/methods' ]
      results = doc['described_by_ssim'].map do |ds_uri|
        res = {}
        pid = ds_uri.split('/')[1]
        dsid = ds_uri.split('/')[2]
        # res[:id] = pid is not used
        # res[:title] = 'description' is not used
        # constant suffix for backwards compatibility with AC2
        filename = "#{pid.gsub(/\:/,'')}_description.xml"
        res[:show_url] = fedora_content_path(:show_pretty, pid, dsid, filename)
        res[:download_url] = fedora_content_path(:download, pid, dsid, filename)
        res
      end
    rescue => e
      Rails.logger.error "In get_metadata_list: #{e.message}"
      results = []
    end

    return results
  end

  def exclusive_feature_search?(feature)
    return false if params[:q].present? || params.fetch(:f, {}).keys.length > 1

    params.dig(:f, :featured_search) == [feature.slug]
  end

  ############### Copied from Blacklight CatalogHelper #####################

  def itemscope_itemtype
    url_from_map = blacklight_config[:itemscope][:itemtypes][@document['genre_ssim']]
    if url_from_map.nil?
      'http://schema.org/CreativeWork'
    else
      url_from_map
    end
  end
end
