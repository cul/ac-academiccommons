module ApplicationHelper
  def document_author
    @document[CatalogController.blacklight_config[:show][:author]]
  end

  # Looks for SVG image in assets directory and outputs XML text
  # rubocop:disable Rails/OutputSafety
  def svg(name)
    file_path = Rails.root.join('app', 'assets', 'images', "#{name}.svg")
    return File.read(file_path).html_safe if File.exist?(file_path)
    '(not found)'
  end
  # rubocop:enable Rails/OutputSafety

  def highwire_press_tags(name, content)
    safe_join(
      Array.wrap(content).map do |c|
        tag 'meta', name: name, content: c
      end
    )
  end
end
