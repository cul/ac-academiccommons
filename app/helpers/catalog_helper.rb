require 'academic_commons'

module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include ApplicationHelper
  include AcademicCommons::Listable

  delegate :repository, to: :controller

  # Adds handle or doi prefix if necessary. Makes field a clickable link.
  def link_identifier(**options)
    value = (options[:value].is_a? Array) ? options[:value].first : options[:value]
    url = AcademicCommons.identifier_url(options[:value])
    link_to url, url
  end

  def concat_grantor(**options)
    [options[:value], options[:document]['degree_grantor_ssim']].join(', ')
  end

  def get_total_count
    date_trend.counts[:total]
  end

  def get_count_by_year
    date_trend.counts[:last_year]
  end

  def get_count_by_month
    date_trend.counts[:last_month]
  end

  def date_trend
    @date_trend ||= AcademicCommons::DateTrend.new('record_creation_date', ContentAggregator)
  end

  def build_recent_updated_list
    query_params = {
      q: '', fl: 'title_display, id, author_facet, record_creation_date',
      sort: 'record_creation_date desc',
      fq: ['author_facet:*', "has_model_ssim:\"#{ContentAggregator.to_class_uri}\""],
      start: 0, rows: 100}
    build_distinct_authors_list(query_params)
  end

  def build_distinct_authors_list(query_params, authors = [], results = [])
    response = repository.search(query_params)['response']
    return results unless response['docs'].present?

    response['docs'].each do |r|
      new_authors = r['author_facet'] - authors if r['author_facet']

      next unless new_authors.present?
      authors.concat new_authors
      results << r
      break if(results.length == blacklight_config[:max_most_recent])
    end
    more_items = query_params[:start] + query_params[:rows] < response['numFound']
    if(results.length < blacklight_config[:max_most_recent] && more_items)
      query_params[:start] = query_params[:start] + query_params[:rows]
      build_distinct_authors_list(query_params, authors, results)
    else
      results
    end
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

  # TODO: Move to a browse controller
  def get_subjects_list
    single_facet_values('subject_facet')
  end

  # TODO: Move to a browse controller
  def get_departments_list
    single_facet_values('department_facet')
  end

  # TODO: Move to a browse controller
  def get_department_facet_list(department)
    query_params = {q: '', fq: 'department_facet:"' + department + '"', rows: '0', 'facet.limit' => -1 }
    solr_results = repository.search(query_params)
    facet_field_results = solr_results.facet_counts['facet_fields']
    collect_facet_field_values(facet_field_results).delete_if do |k,v|
      k == 'department_facet' || k == 'organization_facet'
    end
  end

  def thumbnail_for_resource(resource)
    extension = get_file_extension(resource[:filename].to_s)
    thumbnail_folder_path = Rails.root.to_s + '/app/assets/images/thumbnail_icons/'
    if(!extension.nil? && !extension.empty?)
      thumbnail_file_name = extension + '.png'
    else
      thumbnail_file_name = [:content_type]
      thumbnail_file_name['/'] = '_'
      thumbnail_file_name += '.png'
    end

    if(!File.file?(thumbnail_folder_path + thumbnail_file_name))
      thumbnail_file_name = 'default.png'
    end

    return thumbnail_file_name
  end

  def get_file_extension(filename)
    filename.to_s.split('.').last.strip
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

  ############### Copied from Blacklight CatalogHelper #####################

  def pdf_urls
    urls = []
    if(@document != nil)
      resource_list = build_resource_list(@document)
      resource_list.each do |resource|
           urls.push( 'http://' + request.host_with_port + resource[:download_path] )
       end
     end
     return urls
  end

  def itemscope_itemtype
    url_from_map = blacklight_config[:itemscope][:itemtypes][@document['genre_facet']]
    if url_from_map.nil?
      'http://schema.org/CreativeWork'
    else
      url_from_map
    end
  end
end
