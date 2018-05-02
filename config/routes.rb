Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  devise_for :users, controllers: { sessions: 'users/sessions', :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    get 'sign_in',  to: 'users/sessions#new',     as: :new_user_session
    get 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
  end

  root to: "catalog#home"

  get '/about',    to: 'info#about',    as: 'about'
  get '/policies', to: 'info#policies', as: 'policies'
  get '/faq',      to: 'info#faq',      as: 'faq'
  get '/api',      to: 'info#api',      as: 'api_documentation'

  mount API => '/'

  # Browsing routes
  get '/catalog/browse/departments', to: 'catalog#browse_department', as: 'departments_browse'
  get '/catalog/browse/subjects',    to: 'catalog#browse_subject',    as: 'subjects_browse'
  get '/catalog/browse/departments/:id', :to => 'catalog#browse_department', :as => 'department_browse'
  get '/catalog/browse' => redirect('/catalog/browse/subjects')

  get '/catalog/streaming/:id', :to => 'catalog#streaming', :as => 'streaming'

  # Blacklight routes
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new
  concern :oai_provider, BlacklightOaiProvider::Routes.new

  resource :catalog, only: [:index], as: 'catalog', path: 'search', controller: 'catalog', constraints: { id: /.*/ } do
    concerns :oai_provider
    concerns :searchable
    concerns :range_searchable
  end

  # Routes for solr document
  # Instead of specifying solr routes as:
  #   resources :solr_document, only: [:show], controller: 'catalog', path: 'doi', constraints: { id: /.*/ } do
  #     concerns :exportable
  #   end
  # Specifying routes using glob (*) in id param, this way slashes and period are accepted as part of the id.
  match 'doi/*id/email', to: 'catalog#email', via: [:get, :post], as: :email_solr_document
  match 'doi/email',     to: 'catalog#email', via: [:get, :post], as: :email_solr_document_index
  match 'doi/*id',       to: 'catalog#show',  via: :get,          as: :solr_document

  mount Blacklight::Engine => '/'

  # RESTful routes for reindex API, working around Blacklight route camping
  delete '/solr_documents/:id', to: 'solr_documents#destroy'
  put '/solr_documents/:id', to: 'solr_documents#update'
  get '/solr_documents/:id', to: 'solr_documents#show'

  resources :email_preferences

  get '/download/fedora_content/:download_method/:uri/:block/:filename', to: 'download#fedora_content', as: 'fedora_content',
    block: /(DC|CONTENT|content|SOURCE|descMetadata)/,
    uri: /.+/, filename: /.+/, download_method: /(download|show|show_pretty)/

  get '/download/download_log/:id', to: 'download#download_log', as: 'download_log'

  match '/statistics/detail_report',        to: 'statistics#detail_report',        via: [:get, :post]
  match '/statistics/all_author_monthlies', to: 'statistics#all_author_monthlies', via: [:get, :post]
  get '/statistics/generic_statistics',     to: 'statistics#generic_statistics'
  get '/statistics/send_csv_report',        to: 'statistics#send_csv_report'
  get '/statistics/school_statistics',      to: 'statistics#school_statistics'
  get '/statistics/common_statistics_csv',  to: 'statistics#common_statistics_csv'
  get '/statistics/unsubscribe_monthly',    to: 'statistics#unsubscribe_monthly'
  get '/statistics/statistic_res_list',     to: 'statistics#statistic_res_list'
  get '/statistics/total_usage_stats',      to: 'statistics#total_usage_stats'

  match '/deposit/submit', to: 'deposit#submit', via: [:get, :post]
  get '/deposit',          to: 'deposit#index', as: 'deposit'
  match '/deposit/submit_author_agreement', to: 'deposit#submit_author_agreement', via: [:get, :post]
  get '/deposit/agreement_only'

  get '/admin',                   to: 'admin#index',                 as: 'admin'
  get '/admin/deposit',           to: 'admin#deposits'
  get '/admin/deposits/:id',      to: 'admin#show_deposit',          as: 'show_deposit'
  get '/admin/deposits/:id/file', to: 'admin#download_deposit_file', as: 'download_deposit_file'
  get '/admin/agreements',        to: 'admin#agreements'

  match '/admin/edit_alert_message', to: 'admin#edit_alert_message', via: [:get, :post]

  namespace :admin do
    get 'author_affiliation_report/index'
    get 'author_affiliation_report/create'
  end

  get '/emails/get_csv_email_form', to: 'emails#get_csv_email_form'

  get '/sitemap.xml', to: 'sitemap#index', format: 'xml'

  get '/logs/all_author_monthly_reports_history', to: 'logs#all_author_monthly_reports_history'
  get '/logs/log_form',                           to: 'logs#log_form'
  get '/logs/ingest_history',                     to: 'logs#ingest_history'

  # Route used to render error page.
  get '/500', to: 'errors#internal_server_error'

  # Handle server redirects to /item/:id. This route will redirect those requests
  # to /catalog/:id.
  get '/item/:id',    to: 'catalog#legacy_show'
  get '/catalog/:id', to: 'catalog#legacy_show'
end
