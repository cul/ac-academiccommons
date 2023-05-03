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
    caption_link = "https://academiccommons.columbia.edu/doi/10.7916/3xat-cw21/captions"
    url = "https://firehose.cul.columbia.edu:8443/digital-access-mediacache/_definst_/mp4:digital/access/derivativo/a6/bb/1c/a6bb1c511691d5cda9d68a485d6bc60c12f24a01189534390fd65e5eb13b8a76/access.mp4/playlist.m3u8?wowzaendtime=1683137365&wowzastarttime=1683126565&wowzahash=nt2I3s9Y0SW3VjoQPqqeh4twrwC0SN_QbghdjyCSplg="
    tag.div do
           %(
            
           <video 
            class="video-js vjs-big-play-centered" 
            controls
            responsive
            fluid="true"
            fullwindow
            autoplay="false"
            preload="false"
            style=""
            data-brand-link="#{brand_link}"
            data-setup='{}'
          >
          #{source_element(url, caption_link)}
          </video>
          
          ).html_safe
    end
  end

  def audio_player(url, brand_link, caption_link)
    tag.div do
           %(
            
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
