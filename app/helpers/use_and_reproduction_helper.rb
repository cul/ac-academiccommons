module UseAndReproductionHelper
  IN_COPYRIGHT = 'http://rightsstatements.org/vocab/InC/1.0/'.freeze
  CC0 = 'https://creativecommons.org/publicdomain/zero/1.0/'.freeze
  CC_EXCLUSIVE_LICENSES = %i[sa nd].freeze
  CC_LICENSE_LABELS = {
    by: 'Attribution',
    nc: 'NonCommercial',
    sa: 'ShareAlike',
    nd: 'NoDerivatives'
  }.freeze

  def use_and_reproduction_display(uri)
    if uri&.starts_with?('https://creativecommons.org/licenses/')
      cc_license(uri)
    elsif uri == CC0
      cc0_designation
    elsif uri == IN_COPYRIGHT
      in_copyright
    end
  end

  # expect a uri with a path such as /licenses/by-nc-sa/4.0/
  # the final slash will be trimmed by URI
  def cc_license_attributes(uri)
    segments = URI(uri).path.split('/')
    return nil unless segments.present? && segments.length == 4 && segments[3] =~ /\d+\.\d+/
    license_attributes = {
      version: segments[3]
    }
    return nil unless (license_attributes[:logos] = parse_cc_license_segments(segments[2]))
    license_attributes[:name] = license_attributes[:logos].map { |license| CC_LICENSE_LABELS[license] }.join('-')
    license_attributes[:name] << " #{segments[3]} International"
    license_attributes[:uri] = "https://creativecommons.org/licenses/#{license_attributes[:logos].join('-')}/#{license_attributes[:version]}/"
    license_attributes[:logos].unshift :cc
    license_attributes
  end

  def parse_cc_license_segments(path_segment)
    cc_license_segments = []
    path_segment.downcase.split('-').uniq.tap do |logos|
      return nil unless logos.delete('by')
      cc_license_segments << :by
      cc_license_segments << :nc if logos.delete('nc')
      cc_license_segments << :sa if logos.delete('sa')
      cc_license_segments << :nd if logos.delete('nd')
    end
    return nil if CC_EXCLUSIVE_LICENSES & cc_license_segments == CC_EXCLUSIVE_LICENSES
    cc_license_segments
  end

  def cc_license(uri)
    license_attributes = cc_license_attributes(uri)
    return unless license_attributes.present?
    name = license_attributes[:name]
    logos = license_attributes[:logos]
    uri = license_attributes[:uri]

    image = content_tag(:a, class: 'license', rel: 'license', target: '_blank', href: uri) do
      content_tag(:span, 'aria-label': "Creative Commons #{name} License") do
        safe_join logos.map { |logo| content_tag(:span, cc_img_tag(logo)) }
      end
    end
    # rubocop:disable Rails/OutputSafety
    text = content_tag(:span) do
      'This work is licensed under a '.html_safe + content_tag(:a, "Creative Commons #{name} License", rel: 'license', href: uri)
    end
    # rubocop:enable Rails/OutputSafety
    image.concat(tag(:br)).concat(text)
  end

  def cc_img_tag(logo)
    tag(:img, alt: "cc #{logo}", src: asset_pack_path("media/images/creative_commons/#{logo}.svg"))
  end

  def cc0_designation
    image = content_tag(:a, class: 'license', rel: 'license', target: '_blank', href: CC0) do
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
      tag(:img, height: '40', alt: 'In Copyright', src: asset_pack_path("media/images/in-copyright.svg"))
    end

    text = content_tag(:a, 'All Rights Reserved', target: '_blank', href: IN_COPYRIGHT)
    image.concat(tag(:br)).concat(text)
  end
end
