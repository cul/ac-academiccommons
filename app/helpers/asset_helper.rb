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
    url = 'https://firehose.cul.columbia.edu:8443/digital-access-mediacache/_definst_/mp4:digital/access/derivativo/a6/bb/1c/a6bb1c511691d5cda9d68a485d6bc60c12f24a01189534390fd65e5eb13b8a76/access.mp4/playlist.m3u8?wowzaendtime=1684258026&wowzastarttime=1684247226&wowzahash=ri5rugiT3Pw3AoX9yTXdX491JiQMKFmSKSvHqXOusfw='
    # rubocop:enable Lint/ShadowedArgument
    logo_attr = "player-logo=\"#{asset_pack_path 'media/images/logo-media-player-badge-small.svg'}\""
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
