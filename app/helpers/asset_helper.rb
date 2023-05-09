module AssetHelper
  def player(document, brand_link)
    caption_link = captions_download_url(document['cul_doi_ssi']) if document.captions?
    if document.audio?
      audio_player document.wowza_media_url(request), brand_link, caption_link
    elsif document.video?
      video_player document.wowza_media_url(request), document.image_url(768), brand_link, caption_link
    else
      tag.div 'Not a playable asset'
    end
  end

  def video_player(url, _poster_path, brand_link, caption_link)
    # rubocop:disable Lint/ShadowedArgument
    # hardcoded url for testing
    url = ''
    # rubocop:enable Lint/ShadowedArgument
    logo_attr = "player-logo=\"#{asset_pack_path 'media/images/logo-media-player-badge.svg'}\""
    tag.div do
      # rubocop:disable Rails/OutputSafety
      %(
           <video class="video-js vjs-big-play-centered" controls  responsive="true"  fluid="true"  preload="auto"
            data-brand-link="#{brand_link}" data-setup='{}'  #{logo_attr} >
            #{source_element(url, caption_link)}
          </video>
          ).html_safe
      # rubocop:enable Rails/OutputSafety
    end
  end

  def audio_player(url, brand_link, _caption_link)
    tag.div do
      # rubocop:disable Rails/OutputSafety
      %(
           <audio  class="video-js vjs-big-play-centered" controls  responsive="true"  fluid="true"  preload="auto"
            width="1024" data-brand-link="#{brand_link}" data-setup='{}' >
            <source type="application/x-mpegURL" src="#{url}">
            #{track_tag}
          </audio>
          ).html_safe
      # rubocop:enable Rails/OutputSafety
    end
  end

  def source_element(url, caption_link)
    track_tag = caption_link ? "<track label=\"English\" kind=\"subtitles\" srclang=\"en\" src=\"#{caption_link}\">" : ''
    # rubocop:disable Rails/OutputSafety
    %(
          <source type="application/x-mpegURL" src="#{url}">
          #{track_tag}
        ).html_safe
    # rubocop:enable Rails/OutputSafety
  end
end
