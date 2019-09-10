module AssetHelper
  def player(document, brand_link)
    if document.audio?
      audio_player document.wowza_media_url(request), brand_link
    elsif document.video?
      video_player document.wowza_media_url(request), document.image_url(768), brand_link
    else
      tag.div 'Not a playable asset'
    end
  end

  def video_player(url, poster_path, brand_link)
    tag.div class: 'mediaelement-player', style: 'width:100%;height:100%;' do
      tag.video width: 1024, height: 576, style: 'max-width:100%;', poster: poster_path, controls: 'controls', preload: 'none', data: { brand_link: brand_link } do
        tag.source type: 'application/x-mpegURL', src: url
      end
    end
  end

  def audio_player(url, brand_link)
    tag.div class: 'mediaelement-player' do
      tag.audio width: 1024, controls: 'controls', preload: 'none', data: { brand_link: brand_link } do
        tag.source type: 'application/x-mpegURL', src: url
      end
    end
  end
end
