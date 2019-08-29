module AssetHelper
  def player(document)
    if document.audio?
      audio_player document.wowza_media_url(request)
    elsif document.video?
      video_player document.wowza_media_url(request), document.image_url(768)
    else
      tag.div 'Not a playable asset'
    end
  end

  def video_player(url, poster_path)
    tag.div class: 'mediaelement-player' do
      tag.video class: 'mejs__player', style: 'width:100%;height:100%;', poster: poster_path, controls: 'controls', preload: 'none' do
        tag.source type: 'application/x-mpegURL', src: url
      end
    end
  end

  def audio_player(url)
    tag.div class: 'mediaelement-player' do
      tag.audio class: 'mejs__player', style: 'width:100%;', controls: 'controls', preload: 'none' do
        tag.source type: 'application/x-mpegURL', src: url
      end
    end
  end
end
