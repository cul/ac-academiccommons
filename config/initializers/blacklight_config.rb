# -*- encoding : utf-8 -*-
# You can configure Blacklight from here. 
#   
#   Blacklight.configure(:environment) do |config| end
#   
# :shared (or leave it blank) is used by all environments. 
# You can override a shared key by using that key in a particular
# environment's configuration.
# 
# If you have no configuration beyond :shared for an environment, you
# do not need to call configure() for that envirnoment.
# 
# For specific environments:
# 
#   Blacklight.configure(:test) {}
#   Blacklight.configure(:development) {}
#   Blacklight.configure(:production) {}
# 

Blacklight.configure(:shared) do |config|

  config[:default_solr_params] = {
    :qt => "search",
    :per_page => 10 
  }
 
  # solr field values given special treatment in the show (single result) view
  config[:show] = {
    :html_title => "title_display",
    :heading => "title_display",
    :display_type => "format",
    :genre => "genre_facet",
    :author => "author_display"
  }

  # solr fld values given special treatment in the index (search results) view
  config[:index] = {
    :show_link => "title_display",
    :num_per_page => 10,
    :record_display_type => "format"
  }

  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display
  # TODO: Reorganize facet data structures supplied in config to make simpler
  # for human reading/writing, kind of like search_fields. Eg,
  # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
  config[:facet] = {
    :field_names => (facet_fields = [
       "author_facet",
       "department_facet",
       "subject_facet",
       "series_facet",
       "genre_facet",
       "type_of_resource_facet",
       "language",
       "pub_date_facet"
    ]),
    :labels => {
      "author_facet"      => "Author",
      "department_facet"  => "Department",
      "subject_facet"     => "Subject",
      "genre_facet"       => "Content Type",
      "pub_date_facet"    => "Date",
      "series_facet"      => "Series",
      "language"          => "Language",
      "type_of_resource_facet" => "Resource Type"
      
    },
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
    :limits => {
       "author_facet"     => 2,
       "department_facet" => 2,
       "subject_facet"    => 2,
       "genre_facet"      => 2,
       "pub_date_facet"   => 2,
       "series_facet"     => 2
    }
  }

  # Have BL send all facet field names to Solr, which has been the default
  # previously. Simply remove these lines if you'd rather use Solr request
  # handler defaults, or have no facets.
  config[:default_solr_params] ||= {}
  config[:default_solr_params][:"facet.field"] = facet_fields

  # solr fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display 
  config[:index_fields] = {
    :field_names => [
      "author_display",
      "pub_date_facet",
      "subject_facet",
      "genre_facet",
      "publisher",
      "handle"
    ],
    :labels => {
      "author_display"          => "Author(s):",
      "pub_date_facet"          => "Date:",
      "subject_facet"           => "Subject:",
      "genre_facet"             => "Content Type:",
      "publisher"               => "Publisher:",
      "handle"			=> "Permanent URL:"
    }
  }

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display 
  config[:show_fields] = {
    :field_names => [
      "title_display",
      "author_facet",
      "thesis_advisor",
      "pub_date_facet",
      "genre_facet",
      "originator_department",
      "volume",
      "handle",
      "url",
      "series_facet",
      "part_number",
      "book_journal_title",
      "media_type_facet",
      "table_of_contents", 
      "geographic_area_display", 
      "book_author", 
      "format", 
      "notes", 
      "publisher", 
      "publisher_location", 
      "abstract", 
      "subject_facet",
      "isbn",
      "issn",
      "doi"
      
    ],
    :labels => {
      "title_display"           => "Title:",
      "author_facet"            => "Author(s):",
      "thesis_advisor"          => "Thesis Advisor(s):",
      "pub_date_facet"          => "Date:",
      "genre_facet"             => "Type:",
      "originator_department"   => "Department:",
      "volume"                  => "Volume:",
      "handle"                  => "Permanent URL:",
      "url"                     => "Streaming URL:",
      "series_facet"            => "Series:",
      "part_number"             => "Part Number:",
      "book_journal_title"      => "Book/Journal Title:",
      "media_type_facet"        => "Media Type:",
      "table_of_contents"       => "Table of Contents:", 
      "geographic_area_display" => "Geographic Area:", 
      "book_author"             => "Book Author:", 
      "format"                  => "Format:", 
      "notes"                   => "Notes:", 
      "publisher"               => "Publisher:", 
      "publisher_location"      => "Publisher Location:", 
      "abstract"                => "Abstract:", 
      "subject_facet"           => "Subject(s):", 
      "isbn"                    => "ISBN:",
      "issn"                    => "ISSN:",
      "doi"                     => "DOI:"
    },
    :itemprops => {
      "title_display"           => "name",
      "abstract"                => "description",
      "subject_facet"           => "keywords",  
      "author_facet"            => "creator",
      "pub_date_facet"          => "datePublished",
      "genre_facet"             => "genre",
      "handle"                  => "url"
    },   
    :linked => {
      "author_facet"  => "facet",
      "genre_facet"   => "facet",
      "handle"        => "url",
      "subject_facet" => "facet",
      "series_facet"  => "facet"
    }
  }


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
  # urls.  A display label will be automatically calculated from the :key,
  # or can be specified manually to be different. 
  config[:search_fields] ||= []

  # This one uses all the defaults set by the solr request handler. Which
  # solr request handler? The one set in config[:default_solr_parameters][:qt],
  # since we aren't specifying it otherwise. 
  config[:search_fields] << {
    :key => "all_fields",  
    :display_label => 'All Fields'   
  }

  # Now we see how to over-ride Solr request handler defaults, in this
  # case for a BL "search field", which is really a dismax aggregate
  # of Solr search fields. 
  config[:search_fields] << {
    :key => 'title',     
    # solr_parameters hash are sent to Solr as ordinary url query params. 
    :solr_parameters => {
      :"spellcheck.dictionary" => "title"
    },
    # :solr_local_parameters will be sent using Solr LocalParams
    # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    # Solr parameter de-referencing like $title_qf.
    # See: http://wiki.apache.org/solr/LocalParams
    :solr_local_parameters => {
      :qf => "$title_qf",
      :pf => "$title_pf"
    }
  }
  config[:search_fields] << {
    :key =>'author',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "author" 
    },
    :solr_local_parameters => {
      :qf => "$author_qf",
      :pf => "$author_pf"
    }
  }

  # Specifying a :qt only to show it's possible, and so our internal automated
  # tests can test it. In this case it's the same as 
  # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
  config[:search_fields] << {
    :key => 'subject', 
    :qt=> 'search',
    :solr_parameters => {
      :"spellcheck.dictionary" => "subject"
    },
    :solr_local_parameters => {
      :qf => "$subject_qf",
      :pf => "$subject_pf"
    }
  }
  
  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  # label is key, solr field is value
  config[:sort_fields] ||= []
  config[:sort_fields] << ['relevance', 'score desc, pub_date_sort desc, title_sort asc']
  config[:sort_fields] << ['year', 'pub_date_sort desc, title_sort asc']
  config[:sort_fields] << ['author', 'author_sort asc, title_sort asc']
  config[:sort_fields] << ['title', 'title_sort asc, pub_date_sort desc']
  
  # If there are more than this many search results, no spelling ("did you 
  # mean") suggestion is offered.
  config[:spell_max] = 5

  # For the most-recent list, this is the max number displayed
  config[:max_most_recent] = 10

  # Add documents to the list of object formats that are supported for all objects.
  # This parameter is a hash, identical to the Blacklight::Solr::Document#export_formats 
  # output; keys are format short-names that can be exported. Hash includes:
  #    :content-type => mime-content-type
  config[:unapi] = {
    'oai_dc_xml' => { :content_type => 'text/xml' } 
  }
  
  config[:feed_rows] = "500"
  

config[:oai] = {

  :provider => {
    :repository_name => 'Columbia University Academic Commons',
    :repository_url => 'http://academiccommons.columbia.edu/catalog/oai',
    :record_prefix => 'academiccommons.columbia.edu',
    :admin_email => 'info@cdrs.columbia.edu',
    :deletion_support => 'persistent',
    :sample_id => 'ac:109660'
  },
  :document => {
    :timestamp => 'record_creation_date',
    :limit => 25
  }
}

  config[:temscope] = {
    :itemtypes => {
      "Articles"                     => "http://schema.org/ScholarlyArticle",
      "Working Papers"               => "http://schema.org/ScholarlyArticle", 
      "Technical reports"            => "http://schema.org/ScholarlyArticle", 
      "Reports"                      => "http://schema.org/CreativeWork",
      "Dissertations"                => "http://schema.org/CreativeWork",
      "Blog posts"                   => "http://schema.org/BlogPosting",
      "Presentations"                => "http://schema.org/CreativeWork",
      "Master's theses"              => "http://schema.org/CreativeWork",
      "Undergraduate theses"         => "http://schema.org/CreativeWork",     
      "Book chapters"                => "http://schema.org/Book",
      "Reviews"                      => "http://schema.org/CreativeWork",
      "Interviews and roundtables"   => "http://schema.org/CreativeWork",   
      "Datasets"                     => "http://schema.org/CreativeWork",
      "Fictional works"              => "http://schema.org/CreativeWork",
      "Images"                       => "http://schema.org/ImageObject",
      "Musical compositions"         => "http://schema.org/CreativeWork",     
      "Books"                        => "http://schema.org/Book",
      "Abstracts"                    => "http://schema.org/CreativeWork",
      "Working Paper"                => "http://schema.org/CreativeWork",
      "Letters"                      => "http://schema.org/CreativeWork",
      "Presentation"                 => "http://schema.org/CreativeWork",
      "Article"                      => "http://schema.org/ScholarlyArticle",
      "Conferences"                  => "http://schema.org/CreativeWork",
      "article"                      => "http://schema.org/ScholarlyArticle",
      "Unpublished papers"           => "http://schema.org/CreativeWork",
      "Technical Report"             => "http://schema.org/ScholarlyArticle",
      "Conference posters"           => "http://schema.org/CreativeWork",
      "Promotional materials"        => "http://schema.org/CreativeWork",
      "Programs"                     => "http://schema.org/CreativeWork",
      "Journals"                     => "http://schema.org/CreativeWork",
      "Preprint"                     => "http://schema.org/ScholarlyArticle",
      "Papers"                       => "http://schema.org/ScholarlyArticle",
      "Other"                        => "http://schema.org/CreativeWork",
      "Notes"                        => "http://schema.org/CreativeWork",
      "Conference proceedings"       => "http://schema.org/CreativeWork"
    }
  }

end

	