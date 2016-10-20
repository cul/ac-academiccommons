AcademicCommons::Application.routes.draw do
  root :to => "catalog#index"

  get "info/about"

  get '/catalog/browse/departments', :to => 'catalog#browse_department', :as => 'departments_browse'
  get '/catalog/browse/subjects', :to => 'catalog#browse_subject', :as => 'subjects_browse'
  get '/catalog/browse/departments/:id', :to => 'catalog#browse_department', :as => 'department_browse'
  get '/catalog/streaming/:id', :to => 'catalog#streaming', :as => 'streaming'
  get '/catalog/browse' => redirect('/catalog/browse/subjects')

  Blacklight.add_routes(self)

  # resources :dmcas, path: "dmca"
  get '/copyright_infringement_notice', to: 'dmcas#new', as: 'dmcas'
  post '/copyright_infringement_notice', to: 'dmcas#create' #, as: 'dmcas'
  get '/notice_received', to: 'dmcas#index'


  resources :email_preferences, :reports


  get '/download/fedora_content/:download_method/:uri/:block/:filename', :to => 'download#fedora_content', :as => "fedora_content",
    :block => /(DC|CONTENT|SOURCE)/,
    :uri => /.+/, :filename => /.+/, :download_method => /(download|show|show_pretty)/

  get '/download/download_log/:id', :to => 'download#download_log', :as => 'download_log'

  match '/access_denied', :to => 'application#access_denied', :as => 'access_denied'

  get '/ingest_monitor/:id', :to => 'ingest_monitor#show', :as => 'ingest_monitor'

  match '/statistics/detail_report',        :to => 'statistics#detail_report', via: [:get, :post]
  match '/statistics/all_author_monthlies', :to => 'statistics#all_author_monthlies', via: [:get, :post]
  get '/statistics/generic_statistics',     :to => 'statistics#generic_statistics'
  get '/statistics/single_pid_stats',       :to => 'statistics#single_pid_stats'
  get '/statistics/single_pid_count',       :to => 'statistics#single_pid_count'
  get '/statistics/send_csv_report',        :to => 'statistics#send_csv_report'
  get '/statistics/school_stats',           :to => 'statistics#school_stats'
  get '/statistics/stats_by_event',         :to => 'statistics#stats_by_event'
  get '/statistics/school_docs_size',       :to => 'statistics#school_docs_size'
  get '/statistics/facetStatsByEvent',      :to => 'statistics#facetStatsByEvent'
  get '/statistics/school_statistics',      :to => 'statistics#school_statistics'
  get '/statistics/docs_size_by_query_facets', :to => 'statistics#docs_size_by_query_facets'
  get '/statistics/common_statistics_csv',  :to => 'statistics#common_statistics_csv'
  get '/statistics/unsubscribe_monthly',    :to => 'statistics#unsubscribe_monthly'

  match '/deposit/submit', :to => 'deposit#submit', via: [:get, :post]
  get '/deposit', :to => 'deposit#index', :as => 'deposit'
  #submit_author_agreement get + post
  #submit_student_agreement

  get '/admin', :to => 'admin#index', :as => 'admin'
  get '/admin/deposit', :to => 'admin#deposits'
  get '/admin/deposits/:id', :to => 'admin#show_deposit', :as => 'show_deposit'
  get '/admin/deposits/:id/file', :to => 'admin#download_deposit_file', :as => 'download_deposit_file'
  get '/admin/agreements', :to => 'admin#agreements'
  get '/admin/student_agreements', :to => 'admin#student_agreements'
  match '/admin/ingest', :to => 'admin#ingest', via: [:get, :post]
  match '/admin/edit_alert_message', :to => 'admin#edit_alert_message', via: [:get, :post]

  get '/emails/get_csv_email_form', :to => 'emails#get_csv_email_form'

  #match ':controller/:action'
  #match ':controller/:action/:id'
  #match ':controller/:action/:id.:format'

  get '/sitemap.xml', :to => 'sitemap#index', :format => 'xml'

  get '/logs/all_author_monthly_reports_history', :to => 'logs#all_author_monthly_reports_history'
  get '/logs/log_form', :to => 'logs#log_form'
  get '/logs/ingest_history', :to => 'logs#ingest_history'

  get '/login',          :to => 'user_sessions#new',          :as => 'new_user_session'
  get '/wind_logout',    :to => 'user_sessions#destroy',      :as => 'destroy_user_session'
  # match 'account',        :to => 'application#account',     :as => 'edit_user_registration'


  get '/about', :to => 'info#about', :as => 'about'
end
