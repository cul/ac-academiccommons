module ApplicationHelper
  # Looks for SVG image in assets directory and outputs XML text
  # rubocop:disable Rails/OutputSafety
  def svg(name)
    Rails.cache.fetch("svg/#{name}") do
      file_path = Rails.root.join('app', 'assets', 'images', "#{name}.svg")

      File.exist?(file_path) ? File.read(file_path).html_safe : '(not found)'
    end
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
