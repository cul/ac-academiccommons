class CatalogController < ApplicationController
  include Blacklight::Catalog
  include BlacklightOaiProvider::Controller

  before_filter :record_view_stats, only: :show

  before_filter :url_decode_f

  helper_method :url_encode_resource, :url_decode_resource

  configure_blacklight do |config|
    # Delete default blacklight components we aren't using
    config.index.document_actions.delete(:bookmark)

    config.show.document_actions.delete(:bookmark)
    config.show.document_actions.delete(:sms)
    config.show.document_actions.delete(:citation)

    config.navbar.partials.delete(:bookmark)
    config.navbar.partials.delete(:saved_searches)
    config.navbar.partials.delete(:search_history)

    config.default_solr_params = {
      qt: 'search',
      fq: ["has_model_ssim:\"#{ContentAggregator.to_class_uri}\""],
      rows: 10,
      fl: '*' # Return all fields
    }

    # solr field configuration for search results/index views
    config.show.title_field = 'title_ssi'
    config.show.display_type_field = 'format'
    config.show.genre = 'genre_ssim'
    config.show.author = 'author_ssim'

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    #config.default_document_solr_params = {
    # :qt => 'document',
    # ## These are hard-coded in the blacklight 'document' requestHandler
    # # fl: '*',
    # # :rows => 1
    # # q: '{!raw f=id v=$id}'
    #}


    # solr field configuration for search results/index views
    config.index.title_field = 'title_ssi'
    config.index.num_per_page = 10
    config.index.display_type_field = 'format'


    # solr fields that will be treated as facets by the blacklight application
    # The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.
    #
    # :show may be set to false if you don't want the facet to be drawn in the
    # facet bar

    config.add_facet_field 'author_ssim',            label: 'Author',        limit: 5
    config.add_facet_field 'department_ssim',        label: 'Academic Unit', limit: 5
    config.add_facet_field 'subject_ssim',           label: 'Subject',       limit: 5
    config.add_facet_field 'genre_ssim',             label: 'Type',          limit: 5
    config.add_facet_field 'degree_level_name_ssim', label: 'Degree Level',  limit: 5
    config.add_facet_field 'pub_date_isi',           label: 'Date',          limit: 5
    config.add_facet_field 'series_ssim',            label: 'Series',        limit: 5
    config.add_facet_field 'language_ssim',          label: 'Language',      limit: 5
    # config.add_facet_field 'type_of_resource_ssim', label: 'Resource Type', if: current_user.admin?

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.

    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display

    config.add_index_field 'author_ssim',  label: 'Authors'
    config.add_index_field 'pub_date_isi', label: 'Date'
    config.add_index_field 'genre_ssim',   label: 'Type'


    # :display configuration is for our customized show view, it describes were on the page it should go.
    config.add_show_field 'pub_date_isi',            display: :tag,    itemprop: 'datePublished'
    config.add_show_field 'genre_ssim',              display: :tag,    itemprop: 'genre'
    config.add_show_field 'degree_level_name_ssim',  display: :tag

    config.add_show_field 'author_ssim',  display: :main_content,  itemprop: 'creator',      link_to_search: 'author_ssim',
                                          separator_options: { words_connector: '; ', two_words_connector: '; ', last_word_connector: '; ' }
    config.add_show_field 'abstract_ssi', display: :main_content,  itemprop: 'description'

    config.add_show_field 'geographic_area_ssim', display: :table, label: 'Geographic Areas',                          link_to_search: 'geographic_area_ssim'
    config.add_show_field 'subject_ssim',         display: :table, label: 'Subjects',         itemprop: 'keywords',    link_to_search: 'subject_ssim'

    config.add_show_field 'book_journal_title_ssi', label: 'Published In'
    config.add_show_field 'publisher_doi_ssi',      label: 'Publisher DOI',                             helper_method: :link_identifier
    config.add_show_field 'volume_ssi',             label: 'Volume'
    config.add_show_field 'issue_ssi',              label: 'Issue'
    config.add_show_field 'pages',                  label: 'Pages', accessor: true, unless: ->(_, _, doc) { doc.pages.blank? }
    config.add_show_field 'uri_ssi',                label: 'Url'
    config.add_show_field 'publisher_ssi',          label: 'Publisher'
    config.add_show_field 'publisher_location_ssi', label: 'Publication Origin'
    config.add_show_field 'series_ssim',            label: 'Series', helper_method: :combine_title_and_part_number
    config.add_show_field 'non_cu_series_ssim',     label: 'Series', helper_method: :combine_title_and_part_number
    config.add_show_field 'part_number',            label: 'Part Number' #series part number
    config.add_show_field 'department_ssim',        label: 'Academic Units',                             link_to_search: 'department_ssim'
    config.add_show_field 'thesis_advisor_ssim',         label: 'Thesis Advisors' #not sure what part of the page this would go on.
    config.add_show_field 'degree',                 label: 'Degree', accessor: true, unless: ->(_, _, doc) { doc.degree.blank? }
    config.add_show_field 'related_url_ssi',        label: 'Related URL'

    config.add_show_field 'notes_ssim',             display: :notes, label: 'Notes'

    # config.add_show_field 'cul_doi_ssi',                  label: 'Persistent URL',   itemprop: 'url',          helper_method: :link_identifier



    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls. A display label will be automatically calculated from the :key,
    # or can be specified manually to be different.

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise.

    config.add_search_field 'all_fields', label: 'All Fields'

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields.

    # config.add_search_field('title') do |field|
    #   # solr_parameters hash are sent to Solr as ordinary url query params.
    #   field.solr_parameters = {
    #     'spellcheck.dictionary': 'title',
    #     qf: '${title_qf}',
    #     pf: '${title_pf}'
    #   }
    # end
    #
    # # Specifying a :qt only to show it's possible, and so our internal automated
    # # tests can test it. In this case it's the same as
    # # config[:default_solr_parameters][:qt], so isn't actually neccesary.
    # config.add_search_field('subject') do |field|
    #   field.qt = 'search'
    #   field.solr_parameters = {
    #     'spellcheck.dictionary': 'subject',
    #     qf: '${subject_qf}',
    #     pf: '${subject_pf}'
    #   }
    # end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    # label is key, solr field is value

    config.add_sort_field('Best Match') do |field|
      field.sort = 'score desc, pub_date_isi desc, title_ssi asc'
      field.label = 'Best Match'
    end

    config.add_sort_field('Published Latest') do |field|
      field.sort = 'pub_date_isi desc, title_ssi asc'
      field.label = 'Published Latest'
    end

    config.add_sort_field('Published Earliest') do |field|
      field.sort = 'pub_date_isi asc, title_ssi asc'
      field.label = 'Published Earliest'
    end

    config.add_sort_field('Title A-Z') do |field|
      field.sort = 'title_ssi asc, pub_date_isi desc'
      field.label = 'Title A-Z'
    end

    config.add_sort_field('Title Z-A') do |field|
     field.sort = 'title_ssi desc, pub_date_isi desc'
     field.label = 'Title Z-A'
    end

    # If there are more than this many search results, no spelling ("did you
    # mean") suggestion is offered.
    config.spell_max = 5

    # Configuration for autocomplete suggestor
    config.autocomplete_enabled = true
    config.autocomplete_path = 'suggest'

    # Add documents to the list of object formats that are supported for all objects.
    # This parameter is a hash, identical to the Blacklight::Solr::Document#export_formats
    # output; keys are format short-names that can be exported. Hash includes:
    #    :content-type => mime-content-type
    config.unapi = {
      'oai_dc_xml' => { content_type: 'text/xml' }
    }

    config.feed_rows = '500'
    config.max_most_recent = 5

    config.oai = {
      provider: {
        repository_name: 'Columbia University Academic Commons',
        repository_url: 'https://academiccommons.columbia.edu/catalog/oai',
        record_prefix: 'oai:academiccommons.columbia.edu',
        admin_email: 'ac@columbia.edu',
        sample_id: 'ac:109660'
      },
      document: {
        limit: 100,
        set_fields: [
          { label: 'degree_level', solr_field: 'degree_level_name_ssim' }
        ]
      }
    }

    config.itemscope = {
      itemtypes: {
        'Articles'                     => 'http://schema.org/ScholarlyArticle',
        'Working Papers'               => 'http://schema.org/ScholarlyArticle',
        'Technical reports'            => 'http://schema.org/ScholarlyArticle',
        'Reports'                      => 'http://schema.org/CreativeWork',
        'Dissertations'                => 'http://schema.org/CreativeWork',
        'Blog posts'                   => 'http://schema.org/BlogPosting',
        'Presentations'                => 'http://schema.org/CreativeWork',
        'Master\'s theses'             => 'http://schema.org/CreativeWork',
        'Undergraduate theses'         => 'http://schema.org/CreativeWork',
        'Book chapters'                => 'http://schema.org/Book',
        'Reviews'                      => 'http://schema.org/CreativeWork',
        'Interviews and roundtables'   => 'http://schema.org/CreativeWork',
        'Datasets'                     => 'http://schema.org/CreativeWork',
        'Fictional works'              => 'http://schema.org/CreativeWork',
        'Images'                       => 'http://schema.org/ImageObject',
        'Musical compositions'         => 'http://schema.org/CreativeWork',
        'Books'                        => 'http://schema.org/Book',
        'Abstracts'                    => 'http://schema.org/CreativeWork',
        'Working Paper'                => 'http://schema.org/CreativeWork',
        'Letters'                      => 'http://schema.org/CreativeWork',
        'Presentation'                 => 'http://schema.org/CreativeWork',
        'Article'                      => 'http://schema.org/ScholarlyArticle',
        'Conferences'                  => 'http://schema.org/CreativeWork',
        'article'                      => 'http://schema.org/ScholarlyArticle',
        'Unpublished papers'           => 'http://schema.org/CreativeWork',
        'Technical Report'             => 'http://schema.org/ScholarlyArticle',
        'Conference posters'           => 'http://schema.org/CreativeWork',
        'Promotional materials'        => 'http://schema.org/CreativeWork',
        'Programs'                     => 'http://schema.org/CreativeWork',
        'Journals'                     => 'http://schema.org/CreativeWork',
        'Preprint'                     => 'http://schema.org/ScholarlyArticle',
        'Papers'                       => 'http://schema.org/ScholarlyArticle',
        'Other'                        => 'http://schema.org/CreativeWork',
        'Notes'                        => 'http://schema.org/CreativeWork',
        'Conference proceedings'       => 'http://schema.org/CreativeWork'
      }
    }

  end

  def browse_department
    render layout: 'catalog_browse'
  end

  def browse_subject
    render layout: 'catalog_browse'
  end

  def url_decode_f
    if(params && params[:f])
      params[:f].each do |name, values|
        i = 0
        values.each do |value|
          params[:f][name][i] = url_decode_resource(value)
          i = i + 1
        end
      end
    end
  end

  def url_encode_resource(value)
    value = CGI::escape(value).gsub(/%2f/i, '%252F').gsub(/\./, '%2E')
  end

  def url_decode_resource(value)
    value = value.gsub(/%252f/i, '%2F').gsub(/%2e/i, '.')
    value = CGI::unescape(value)
  end

  def streaming
    logger.info 'RECORDING STREAMING EVENT'
    record_stats(params['id'], Statistic::STREAM)
    render nothing: true
  end


  private

  def record_view_stats
    record_stats(params['id'], Statistic::VIEW)
  end

  def record_stats(id, event)
    return if is_bot?(request.user_agent)
    Statistic.create!(
      session_id: request.session_options[:id],
      ip_address: request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr,
      event: event, identifier: id, at_time: Time.now()
    )
  end

  def custom_results

   bench_start = Time.now

   if (!params[:id].nil?)
     params[:id] = nil
   end

   params[:page] = nil
   params[:q] = params[:q].to_s
   params[:sort] = (params[:sort].nil?) ? 'record_creation_dtsi desc' : params[:sort].to_s
   params[:rows] = (params[:rows].nil? || params[:rows].to_s == '') ? ((params[:id].nil?) ? blacklight_config[:feed_rows] : params[:id].to_s) : params[:rows].to_s
   params[:fq] = Array(params[:fq]).append("has_model_ssim:\"#{ContentAggregator.to_class_uri}\"")

   extra_params = {}
   extra_params[:fl] = 'title_ssi,id,author_ssim,record_creation_dtsi,cul_doi_ssi,abstract_ssi,author_uni_ssim,subject_ssim,department_ssim,genre_ssim'

   if (params[:f].nil?)
     solr_response = repository.search(params.merge(extra_params))
   else
    #  solr_response = repository.search(self.processed_parameters(params).merge(extra_params))
    solr_params = search_builder.with(params).processed_parameters.merge(extra_params)
    solr_response = repository.search(solr_params)

   end

   document_list = solr_response.docs.collect {|doc| SolrDocument.new(doc, solr_response)}

   document_list.each do |doc|
    doc[:pub_date] = Time.parse(doc[:record_creation_dtsi].to_s).to_s(:rfc822)
   end

   logger.info("Solr fetch: #{self.class}#custom_results (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

   return [solr_response, document_list]
  end
end
