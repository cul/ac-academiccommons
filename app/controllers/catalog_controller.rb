# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController  

  include Blacklight::Catalog
  
  before_filter :record_stats, :only => :show
  unloadable
 
  before_filter :redirect_browse
  before_filter :url_decode_f
  
  helper_method :url_encode_resource, :url_decode_resource
  
  # displays values and pagination links for a single facet field
  def facet
    @pagination = get_facet_pagination(params[:id], params)
    render :layout => false
  end
  
  def browse
    render :layout => "catalog_browse"
  end
  
  def browse_department
    render :layout => "catalog_browse"
  end
  
  def browse_subject
    index
  end
  
  def redirect_browse
    
    if(params[:id].to_s == 'browse')
      redirect_to :action => 'browse', :id => 'subjects'
    end
    
  end
  
  def url_decode_f
    if(params && params[:f])
      params[:f].each do |name, values|
        i = 0
        values.each do |value|
          params[:f][name][i] = url_decode_resource(value)
          i = i + 1
        end
      end
    end
  end
  
  def url_encode_resource(value)
    value = CGI::escape(value).gsub(/%2f/i, '%252F').gsub(/\./, '%2E')
  end
  
  def url_decode_resource(value)
    value = value.gsub(/%252f/i, '%2F').gsub(/%2e/i, '.')
    value = CGI::unescape(value)
  end
  
  private
  
  def record_stats()
    unless is_bot?(request.user_agent)
      Statistic.create!(:session_id => request.session_options[:id], :ip_address => request.env['HTTP_X_FORWARDED_FOR'] || request.remote_addr, :event => "View", :identifier => params["id"], :at_time => Time.now())
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
