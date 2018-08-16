module UseAndReproductionHelper
  IN_COPYRIGHT = 'http://rightsstatements.org/vocab/InC/1.0/'.freeze
  CC0 = 'https://creativecommons.org/publicdomain/zero/1.0/'.freeze
  CC_LICENSES = {
    'https://creativecommons.org/licenses/by/4.0/' => {
      name: 'Attribution 4.0 International', logos: %i[cc by]
    },
    'https://creativecommons.org/licenses/by-sa/4.0/' => {
      name: 'Attribution-ShareAlike 4.0 International', logos: %i[cc by sa]
    },
    'https://creativecommons.org/licenses/by-nd/4.0/' => {
      name: 'Attribution-NoDerivatives 4.0 International', logos: %i[cc by nd]
    },
    'https://creativecommons.org/licenses/by-nc/4.0/' => {
      name: 'Attribution-NonCommercial 4.0 International', logos: %i[cc by nc]
    },
    'https://creativecommons.org/licenses/by-nc-sa/4.0/' => {
      name: 'Attribution-NonCommercial-ShareAlike 4.0 International', logos: %i[cc by nc sa]
    },
    'https://creativecommons.org/licenses/by-nc-nd/4.0/' => {
      name: 'Attribution-NonCommercial-NoDerivatives 4.0 International', logos: %i[cc by nc nd]
    }
  }.freeze

  def use_and_reproduction_display(uri)
    return if uri.blank?

    if uri.starts_with?('https://creativecommons.org/licenses/')
      cc_license(uri)
    elsif uri == CC0
      cc0_designation
    elsif uri == IN_COPYRIGHT
      in_copyright
    end
  end

  def cc_license(uri)
    name = CC_LICENSES[uri][:name]
    logos = CC_LICENSES[uri][:logos]

    image = content_tag(:a, class: 'license', rel: 'license', target: '_blank', href: uri) do
      content_tag(:span, 'aria-label': "Creative Commons #{name} License") do
        safe_join(
          logos.map { |logo| content_tag(:span, cc_img_tag(logo)) }
        )
      end
    end
    # rubocop:disable Rails/OutputSafety
    text = content_tag(:span) do
      'This work is licensed user a '.html_safe + content_tag(:a, "Creative Commons #{name} License", rel: 'license', href: uri)
    end
    # rubocop:enable Rails/OutputSafety
    image.concat(tag(:br)).concat(text)
  end

  def cc_img_tag(logo)
    tag(:img, alt: "cc #{logo}", src: image_path("creative_commons/#{logo}.svg"))
  end

  def cc0_designation
    image = content_tag(:a, rel: 'license', target: '_blank', href: CC0) do
      content_tag(:span, 'aria-label': 'CC0') do
        content_tag(:span, cc_img_tag(:cc)) + content_tag(:span, cc_img_tag(:zero))
      end
    end
    # rubocop:disable Rails/OutputSafety
    text = content_tag(:span) do
      'Copyright and related rights waived via '.html_safe + content_tag(:a, 'CC0', target: '_blank', href: CC0)
    end
    # rubocop:enable Rails/OutputSafety
    image.concat(tag(:br)).concat(text)
  end

  def in_copyright
    image = content_tag(:a, class: 'in-copyright', target: '_blank', href: IN_COPYRIGHT) do
      tag(:img, height: '40', alt: 'In Copyright', src: image_path('in-copyright.svg'))
    end

    text = content_tag(:a, 'All Rights Reserved', target: '_blank', href: IN_COPYRIGHT)

    image.concat(tag(:br)).concat(text)
  end
end
