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

  # Looks for SVG image in assets directory and outputs XML text
  # rubocop:disable Rails/OutputSafety
  def svg(name)
    file_path = Rails.root.join('app', 'assets', 'images', "#{name}.svg")
    return File.read(file_path).html_safe if File.exist?(file_path)
    '(not found)'
  end
  # rubocop:enable Rails/OutputSafety
end
