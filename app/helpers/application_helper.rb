module ApplicationHelper
  def document_author
    @document[CatalogController.blacklight_config[:show][:author]]
  end

  def suggested_citation(document)
    citation = []
    citation << first_names_then_last(document_author || "", ", ")

    unless document["pub_date_facet"].blank? || document['pub_date_facet'][0].blank?
      citation << render_document_show_field_value(document, "pub_date_facet")
    end

    citation << render_document_show_field_value(document, "title_display")
    citation << 'Columbia University Academic Commons'
    citation << render_document_show_field_value(document, "handle") unless document["handle"].blank?
    citation.reject(&:blank?).join(', ').concat('.').html_safe
  end

  def first_names_then_last(last_names_first, sep = "; ")
    last_names_first.split(";").map do |last_name_first|
      first_name_then_last(last_name_first.strip)
    end.join(sep).html_safe
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
end
