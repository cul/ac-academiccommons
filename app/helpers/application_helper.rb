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
  # add active class to current page

  def active_class(link_path)
    current_page?(link_path) ? 'active' : ''
  end

  def title(page_title)
    content_for :page_title, "#{page_title} | #{application_name}"
  end

  def modal(id, size, title)
    # Removed 'fade' class from test environment because the animation prevents forms from being filled in correctly.
    tag.div class: Rails.env.test? ? 'modal' : 'modal fade', id: id, tabindex: '-1', role: 'dialog' do
      tag.div class: "modal-dialog modal-#{size}", role: 'document' do
        tag.div class: 'modal-content' do
          tag.div(class: 'modal-header') {
            tag.button(type: 'button', class: 'close', data: { dismiss: 'modal' }, aria: { label: 'Close' }) {
              tag.span sanitize('&times;'), aria: { hidden: true }
            }.concat(tag.h3(title, class: 'modal-title'))
          }.concat(tag.div(class: 'modal-body') { yield if block_given? })
        end
      end
    end
  end
end
