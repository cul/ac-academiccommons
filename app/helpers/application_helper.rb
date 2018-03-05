module ApplicationHelper
  def document_author
    @document[CatalogController.blacklight_config[:show][:author]]
  end

  def metaheader_fix_if_needed(name, content)

    if(name == 'citation_author')
      parts = content.split(',')
      content = ''
      parts.reverse.each do |part|
        content += part + ' '
      end
      content.strip!
    end

    return content
  end
end
