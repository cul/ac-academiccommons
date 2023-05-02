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

  def video_player(url, poster_path, brand_link, caption_link)
# for dev purposes, hardcode these two values:
    caption_link = ""
    url = ""
    tag.div do
           %(
            <div class="mediaelement-player">
           <video 
            class="video-js" 
            controls
            responsive
            fullwindow
            autoplay="false"
            preload="auto"
            poster="#{poster_path}"
            style="position: absolute; top: 0; left: 0;"
            data-brand-link="#{brand_link}"
            data-setup='{}'
          >
          #{source_element(url, caption_link)}
          </video>
          </div>
          ).html_safe
    end
  end

  def audio_player(url, brand_link, caption_link)
    tag.div do
           %(
            <div class="mediaelement-player">
           <audio 
            class="video-js" 
            controls
            responsive
            autoplay="false"
            width="1024"
            preload="auto"
            data-brand-link="#{brand_link}"
            data-setup='{}'
          >
        <source type="application/x-mpegURL" src="#{url}">
        #{track_tag}
          </audio>
          </div>
          ).html_safe
    end
  end


  def source_element(url, caption_link)
        track_tag = caption_link ? "<track label=\"English\" kind=\"subtitles\" srclang=\"en\" src=\"#{caption_link}\">" : ""
        %(
          <source type="application/x-mpegURL" src="#{url}">
          #{track_tag}
        ).html_safe
  end
end
