class ApplicationController < ActionController::Base

  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  protect_from_forgery

  layout "application"

  before_filter :check_new_session

  helper :all # include all helpers, all the time
  helper_method :user_session, :current_user_session, :current_user, :fedora_config, :solr_config, :relative_root # share some methods w/ views via helpers

  def fedora_config
    @fedora_config ||= Rails.configuration.fedora
  end

  def solr_config
    @solr_config ||= Rails.configuration.solr
  end

  def fedora_server
    @fedora_server ||= Cul::Fedora::Server.new(fedora_config)
  end

  def solr_server
    @solr_server ||= Cul::Fedora::Solr.new(solr_config)
  end

  def relative_root
    Rails.configuration.relative_root || ""
  end

  def store_location
    session[:return_to] = request.fullpath
  end

  def redirect_back_or_default(default, additional_params)
    to_url = session[:return_to] || default
    if(additional_params)
      if(to_url.include?('?'))
        to_url = to_url + "&" + additional_params
      else
        to_url = to_url + "?" + additional_params
      end
    end
    redirect_to(to_url)
    session[:return_to] = nil
  end

  def pid_exists?(pid)
    `ps -p #{pid}`.include?(pid)
  end


  ############################################
  ####  Application user-related methods  ####
  ############################################

  def access_denied
    render :template => 'access_denied'
  end

  def check_new_session
    if(params[:new_session])
      current_user.set_personal_info_via_ldap
      current_user.save
    end
  end

  def require_user
     unless current_user
       store_location
       redirect_to new_user_session_path
       return false
     end
     return false
  end

  def require_admin
    if current_user
      unless current_user.admin
        redirect_to access_denied_url
      end
    else
      store_location
      redirect_to new_user_session_path
      return false
    end
    return false
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to root_url
      return false
    end
  end

  def user_session
    return @user_session if defined?(@user_session)
    @user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = user_session && user_session.user
  end

  @@robots = ['Alexandria(\s|\+)prototype(\s|\+)project', 'AllenTrack', 'Arachmo', 'Brutus\/AET', 'China\sLocal\sBrowse\s2\.6', 'Code\sSample\sWeb\sClient', 'ContentSmartz', 'DSurf', 'DataCha0s\/2\.0', 'Demo\sBot', 'EmailSiphon', 'EmailWolf', 'FDM(\s|\+)1', 'Fetch(\s|\+)API(\s|\+)Request', 'GetRight', 'Goldfire(\s|\+)Server', 'Googlebot', 'HTTrack', 'LOCKSS', 'LWP\:\:Simple', 'MSNBot', 'Microsoft(\s|\+)URL(\s|\+)Control', 'Milbot', 'MuscatFerre', 'NABOT', 'NaverBot', 'Offline(\s|\+)Navigator', 'OurBrowser', 'Python\-urllib', 'Readpaper', 'Strider', 'T\-H\-U\-N\-D\-E\-R\-S\-T\-O\-N\-E', 'Teleport(\s|\+)Pro', 'Teoma', 'Wanadoo', 'Web(\s|\+)Downloader', 'WebCloner', 'WebCopier', 'WebReaper', 'WebStripper', 'WebZIP', 'Webinator', 'Webmetrics', 'Wget', 'Xenu(\s|\+)Link(\s|\+)Sleuth', '[+:,\.\;\/\\-]bot', '[^a]fish', '^voyager\/', 'acme\.spider', 'alexa', 'almaden', 'appie', 'architext', 'archive\.org_bot', 'arks', 'asterias', 'atomz', 'autoemailspider', 'awbot', 'baiduspider', 'bbot', 'biadu', 'biglotron', 'bjaaland', 'blaiz\-bee', 'bloglines', 'blogpulse', 'boitho\.com\-dc', 'bookmark\-manager', 'bot', 'bot[+:,\.\;\/\\-]', 'bspider', 'bwh3_user_agent', 'celestial', 'cfnetwork|checkbot', 'combine', 'commons\-httpclient', 'contentmatch', 'core', 'crawl', 'crawler', 'cursor', 'custo', 'daumoa', 'docomo', 'dtSearchSpider', 'dumbot', 'easydl', 'exabot', 'fast-webcrawler', 'favorg', 'feedburner', 'feedfetcher\-google', 'ferret', 'findlinks', 'gaisbot', 'geturl', 'gigabot', 'girafabot', 'gnodspider', 'google', 'grub', 'gulliver', 'harvest', 'heritrix', 'hl_ftien_spider', 'holmes', 'htdig', 'htmlparser', 'httpget\-5\.2\.2', 'httpget\?5\.2\.2', 'httrack', 'iSiloX', 'ia_archiver', 'ichiro', 'iktomi', 'ilse', 'internetseer', 'intute', 'java', 'java\/', 'jeeves', 'jobo', 'kyluka', 'larbin', 'libwww', 'libwww\-perl', 'lilina', 'linkbot', 'linkcheck', 'linkchecker', 'linkscan', 'linkwalker', 'livejournal\.com', 'lmspider', 'lwp', 'lwp\-request', 'lwp\-tivial', 'lwp\-trivial', 'lycos[_+]', 'mail.ru', 'mediapartners\-google', 'megite', 'milbot', 'mimas', 'mj12bot', 'mnogosearch', 'moget', 'mojeekbot', 'momspider', 'motor', 'msiecrawler', 'msnbot', 'myweb', 'nagios', 'netcraft', 'netluchs', 'ng\/2\.', 'no_user_agent', 'nomad', 'nutch', 'ocelli', 'onetszukaj', 'perman', 'pioneer', 'playmusic\.com', 'playstarmusic\.com', 'powermarks', 'psbot', 'python', 'qihoobot', 'rambler', 'redalert|robozilla', 'robot', 'robots', 'rss', 'scan4mail', 'scientificcommons', 'scirus', 'scooter', 'seekbot', 'seznambot', 'shoutcast', 'slurp', 'sogou', 'speedy', 'spider', 'spiderman', 'spiderview', 'sunrise', 'superbot', 'surveybot', 'tailrank', 'technoratibot', 'titan', 'turnitinbot', 'twiceler', 'ucsd', 'ultraseek', 'urlaliasbuilder', 'urllib', 'virus[_+]detector', 'voila', 'w3c\-checklink', 'webcollage', 'weblayers', 'webmirror', 'webreaper', 'wordpress', 'worm', 'xenu', 'y!j', 'yacy', 'yahoo', 'yahoo\-mmcrawler', 'yahoofeedseeker', 'yahooseeker', 'yandex', 'yodaobot', 'zealbot', 'zeus', 'zyborg']

  def is_bot?(user_agent)
    return false unless user_agent
    bot = false
    # return user_agent && @@robots.any? { |pattern| user_agent.match(/#{pattern}/) }
    @@robots.each{|pattern|
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
