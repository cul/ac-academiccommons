class DownloadController < ApplicationController
  
  after_filter :record_stats
  
  def fedora_content
      
    url = fedora_config["riurl"] + "/get/" + params[:uri]+ "/" + params[:block]

    cl = HTTPClient.new
    h_cd = "filename=""#{CGI.escapeHTML(params[:filename].to_s)}"""
    h_ct = cl.head(url).header["Content-Type"].to_s
    text_result = nil

    case params[:download_method]
    when "download"
      h_cd = "attachment; " + h_cd 
    when "show_pretty"
      if h_ct.include?("xml")
        xsl = Nokogiri::XSLT(File.read(Rails.root.to_s + "/app/tools/pretty-print.xsl"))
        xml = Nokogiri(cl.get_content(url))
        text_result = xsl.apply_to(xml).to_s
      else
        text_result = "Non-xml content streams cannot be pretty printed."
      end
    end

    if text_result
      headers["Content-Type"] = "text/plain"
      render :text => text_result
    else
        
      headers["Content-Disposition"] = h_cd
      headers["Content-Type"] = h_ct

      
      send_data(cl.get_content(url), :filename => CGI.escapeHTML(params[:filename].to_s), :type => h_ct)
      
    end
  end

  private
  
  def record_stats()
    unless is_bot?(request.user_agent)
      Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "Download", :identifier => params["uri"], :at_time => Time.now())
    end
  end


  def is_bot?(user_agent)
      robots = ['Alexandria(\s|\+)prototype(\s|\+)project', 'AllenTrack', 'Arachmo', 'Brutus\/AET', 'China\sLocal\sBrowse\s2\.6', 'Code\sSample\sWeb\sClient', 'ContentSmartz', 'DSurf', 'DataCha0s\/2\.0', 'Demo\sBot', 'EmailSiphon', 'EmailWolf', 'FDM(\s|\+)1', 'Fetch(\s|\+)API(\s|\+)Request', 'GetRight', 'Goldfire(\s|\+)Server', 'Googlebot', 'HTTrack', 'LOCKSS', 'LWP\:\:Simple', 'MSNBot', 'Microsoft(\s|\+)URL(\s|\+)Control', 'Milbot', 'MuscatFerre', 'NABOT', 'NaverBot', 'Offline(\s|\+)Navigator', 'OurBrowser', 'Python\-urllib', 'Readpaper', 'Strider', 'T\-H\-U\-N\-D\-E\-R\-S\-T\-O\-N\-E', 'Teleport(\s|\+)Pro', 'Teoma', 'Wanadoo', 'Web(\s|\+)Downloader', 'WebCloner', 'WebCopier', 'WebReaper', 'WebStripper', 'WebZIP', 'Webinator', 'Webmetrics', 'Wget', 'Xenu(\s|\+)Link(\s|\+)Sleuth', '[+:,\.\;\/\\-]bot', '[^a]fish', '^voyager\/', 'acme\.spider', 'alexa', 'almaden', 'appie', 'architext', 'archive\.org_bot', 'arks', 'asterias', 'atomz', 'autoemailspider', 'awbot', 'baiduspider', 'bbot', 'biadu', 'biglotron', 'bjaaland', 'blaiz\-bee', 'bloglines', 'blogpulse', 'boitho\.com\-dc', 'bookmark\-manager', 'bot', 'bot[+:,\.\;\/\\-]', 'bspider', 'bwh3_user_agent', 'celestial', 'cfnetwork|checkbot', 'combine', 'commons\-httpclient', 'contentmatch', 'core', 'crawl', 'crawler', 'cursor', 'custo', 'daumoa', 'docomo', 'dtSearchSpider', 'dumbot', 'easydl', 'exabot', 'fast-webcrawler', 'favorg', 'feedburner', 'feedfetcher\-google', 'ferret', 'findlinks', 'gaisbot', 'geturl', 'gigabot', 'girafabot', 'gnodspider', 'google', 'grub', 'gulliver', 'harvest', 'heritrix', 'hl_ftien_spider', 'holmes', 'htdig', 'htmlparser', 'httpget\-5\.2\.2', 'httpget\?5\.2\.2', 'httrack', 'iSiloX', 'ia_archiver', 'ichiro', 'iktomi', 'ilse', 'internetseer', 'intute', 'java', 'java\/', 'jeeves', 'jobo', 'kyluka', 'larbin', 'libwww', 'libwww\-perl', 'lilina', 'linkbot', 'linkcheck', 'linkchecker', 'linkscan', 'linkwalker', 'livejournal\.com', 'lmspider', 'lwp', 'lwp\-request', 'lwp\-tivial', 'lwp\-trivial', 'lycos[_+]', 'mail.ru', 'mediapartners\-google', 'megite', 'milbot', 'mimas', 'mj12bot', 'mnogosearch', 'moget', 'mojeekbot', 'momspider', 'motor', 'msiecrawler', 'msnbot', 'myweb', 'nagios', 'netcraft', 'netluchs', 'ng\/2\.', 'no_user_agent', 'nomad', 'nutch', 'ocelli', 'onetszukaj', 'perman', 'pioneer', 'playmusic\.com', 'playstarmusic\.com', 'powermarks', 'psbot', 'python', 'qihoobot', 'rambler', 'redalert|robozilla', 'robot', 'robots', 'rss', 'scan4mail', 'scientificcommons', 'scirus', 'scooter', 'seekbot', 'seznambot', 'shoutcast', 'slurp', 'sogou', 'speedy', 'spider', 'spiderman', 'spiderview', 'sunrise', 'superbot', 'surveybot', 'tailrank', 'technoratibot', 'titan', 'turnitinbot', 'twiceler', 'ucsd', 'ultraseek', 'urlaliasbuilder', 'urllib', 'virus[_+]detector', 'voila', 'w3c\-checklink', 'webcollage', 'weblayers', 'webmirror', 'webreaper', 'wordpress', 'worm', 'xenu', 'y!j', 'yacy', 'yahoo', 'yahoo\-mmcrawler', 'yahoofeedseeker', 'yahooseeker', 'yandex', 'yodaobot', 'zealbot', 'zeus', 'zyborg']

      bot = false
      robots.each{|pattern|		
        if(user_agent.match(/#{pattern}/))
		bot = true
		break
	else
		next
	end
	}
     return bot
  end

end


