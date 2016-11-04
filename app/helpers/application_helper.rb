require 'rails_rinku'

module ApplicationHelper

  def application_name
    'Academic Commons'
  end

  def document_type
    @document[CatalogController.blacklight_config[:show][:genre]]
  end

  def document_author
    @document[CatalogController.blacklight_config[:show][:author]]
  end

  def render_document_heading
    heading = ""
     heading += '<h1 class="document_title">' + (document_heading || "") + '</h1>'
#     heading += '<h2 class="author_name">' + first_names_then_last(document_author || "")  + '</h2>'
    heading.html_safe
  end

  def first_names_then_last(last_names_first)

    i = 0
    html = ""
    last_names_first.split(";").each do |last_name_first|
      if(i > 0)
        html << "; "
      end
      html << first_name_then_last(last_name_first.strip)
      i += 1
    end
    return html.html_safe
  end

  def first_names_then_last_suggested_citation(last_names_first)

    i = 0
    html = ""
    last_names_first.split(";").each do |last_name_first|
      if(i > 0)
        html << ", "
      end
      html << first_name_then_last(last_name_first.strip)
      i += 1
    end
    return html.html_safe
  end

  def first_name_then_last(last_name_first)
    if(last_name_first.index(","))
      parts = last_name_first.split(",")
      if parts.length > 1
        fl_name = (parts[1].strip + " " + parts[0].strip).html_safe
      else
        fl_name = (parts[0].strip).html_safe
      end
    else
      fl_name = last_name_first.html_safe
    end

    raw('<a href="' + '/catalog?f[author_facet][]=' + last_name_first + '">' + fl_name + '</a>')
  end


  # RSolr presumes one suggested word, this is a temporary fix
  def get_suggestions(spellcheck)
    words = []
    return words if spellcheck.nil?
    suggestions = spellcheck[:suggestions]
    i_stop = suggestions.index("correctlySpelled")
    0.step(i_stop - 1, 2).each do |i|
      term = suggestions[i]
      term_info = suggestions[i+1]
      origFreq = term_info['origFreq']
      # termInfo['suggestion'] is an array of hashes with 'word' and 'freq' keys
      term_info['suggestion'].each do |suggestion|
        if suggestion['freq'] > origFreq
          words << suggestion['word']
        end
      end
    end
    words
  end
  #
  # facet param helpers ->
  #

  # Standard display of a facet value in a list. Used in both _facets sidebar
  # partial and catalog/facet expanded list. Will output facet value name as
  # a link to add that to your restrictions, with count in parens.
  # first arg item is a facet value item from rsolr-ext.
  # options consist of:
  # :suppress_link => true # do not make it a link, used for an already selected value for instance
  def render_facet_value(facet_solr_field, item, options ={})
    render = link_to_unless(options[:suppress_link], item.value, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select")
    render = render + ("<span class='item_count'> (" + format_num(item.hits) + ")</span>").html_safe
    render.html_safe
  end

  def facet_list_limit
    10
  end

  # Standard display of a SELECTED facet value, no link, special span
  # with class, and 'remove' button.
  def render_selected_facet_value(facet_solr_field, item)
    render = link_to((item.value + "<span class='item_count'> (" + format_num(item.hits) + ")</span>").html_safe, remove_facet_params(facet_solr_field, item.value, params), :class=>"facet_deselect")
    render = render + render_subfacets(facet_solr_field, item)
    render.html_safe
  end

  def render_subfacets(facet_solr_field, item, options ={})
    render = ''
    if (item.instance_variables.include? "@subfacets")
      render = '<span class="toggle">[+/-]</span><ul>'
      item.subfacets.each do |subfacet|
        if facet_in_params?(facet_solr_field, subfacet.value)
          render += '<li>' + render_selected_facet_value(facet_solr_field, subfacet) + '</li>'
        else
          render += '<li>' + render_facet_value(facet_solr_field, subfacet,options) + '</li>'
        end
      end
      render += '</ul>'
      end
      render.html_safe
  end

  def get_last_month_name
    Date.today.ago(1.month).strftime("%B")
  end

  def get_last_month_page_visitors
    return get_analytics("visitors")
  end

  def get_analytics(metrics)

    if(File.exists?("#{Rails.root}/tmp/#{get_last_month_name.downcase}_" + metrics))
      file = File.open("#{Rails.root}/tmp/#{get_last_month_name.downcase}_" + metrics, 'rb')
      return file.read
    else

      require "#{Rails.root}/lib/pagevisits.rb"
      Garb::Session.login(Rails.application.config.google_analytics['username'], Rails.application.config.google_analytics['password'])
      profile = Garb::Management::Profile.all.detect {|p| p.web_property_id == 'UA-10481105-1'}
      ga_results = profile.pagevisits(:start_date => Date.today.ago(1.month).beginning_of_month, :end_date => Date.today.beginning_of_month.ago(1.day))
      if(metrics == "visitors")
        visits = ga_results.to_a[0].visitors
      end
      if(metrics == "visits")
         visits = ga_results.to_a[0].visits
      end
      Dir.glob("#{Rails.root}/tmp/*_" + metrics) do |visits_file|
        File.delete(visits_file)
      end
      File.open("#{Rails.root}/tmp/#{get_last_month_name.downcase}_" + metrics, 'w') { |file| file.write(visits) }
      return visits

     end
  end

  def document_show_fields_linked(name)
    CatalogController.blacklight_config.show_fields[name][:linked]
  end

  def document_render_field_value(field_name, value)

    if(document_show_fields_linked(field_name))
      if(document_show_fields_linked(field_name) == "facet")
        value = '<a href="' + '/catalog?f[' + field_name + '][]=' + value + '">' + value + '</a>'
      elsif(document_show_fields_linked(field_name) == "url")
        value = '<a href="' + value + '">' + value + '</a>'
      end
    end

    if(field_name == "url")
      value = '<a class="fancybox-counter" href="' + value + '">' + value + '</a>'
    end

    return auto_link(value).html_safe
  end

  def metaheader_fix_if_needed(name, content)

    if(name == "citation_author")
      parts = content.split(",")
      content = ""
      parts.reverse.each do |part|
        content += part + " "
      end
      content.strip!
    end

    return content
  end


  def page_location
    if params[:controller] == "catalog"
      if params[:action] == "index" and params[:q].to_s.blank? and params[:f].to_s.blank? and params[:search_field].to_s.blank?
        return "home"
      elsif params[:action] == "index"
        return "search_results"
      elsif params[:action] == "show"
        return "record_view"
      elsif params[:action] == "browse" || params[:action] == "browse_department" || params[:action] == "browse_subject"
        return "browse_view"
      end
    elsif params[:controller] == "advanced"
      return "advanced"
    elsif params[:controller] == "search_history"
      return "search_history"
    else
      return "unknown"
    end
  end

end
