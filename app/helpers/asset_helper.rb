module AssetHelper
  def player(document, brand_link)
    caption_link = captions_download_url(document['cul_doi_ssi']) if captions?(document)
    if document.audio?
      audio_player document.wowza_media_url(request), brand_link, caption_link
    elsif document.video?
      video_player document.wowza_media_url(request), document.image_url(768), brand_link, caption_link
    else
      tag.div 'Not a playable asset'
    end
  end

  def video_player(url, poster_path, brand_link, caption_link)
    tag.div class: 'mediaelement-player' do
      tag.video poster: poster_path, controls: 'controls', preload: 'none', data: { brand_link: brand_link } do
        tag.source type: 'application/x-mpegURL', src: url
        tag.track(label: 'English', kind: 'subtitles', srclang: 'en', src: caption_link) if caption_link
      end
    end
  end

  def audio_player(url, brand_link, caption_link)
    tag.div class: 'mediaelement-player' do
      tag.audio width: 1024, controls: 'controls', preload: 'none', data: { brand_link: brand_link } do
        tag.source type: 'application/x-mpegURL', src: url
        tag.track(label: 'English', kind: 'subtitles', srclang: 'en', src: caption_link) if caption_link
      end
    end
  end

  def captions?(document)
    document['datastreams_ssim']&.include?('captions')
  end
end
