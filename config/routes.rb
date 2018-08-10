require 'resque/server'

Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  devise_for :users, controllers: { sessions: 'users/sessions', omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    get 'sign_in',  to: 'users/sessions#new',     as: :new_user_session
    get 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
  end

  root to: "catalog#home"

  # Static Pages
  get '/about',      to: 'info#about',      as: 'about'
  get '/policies',   to: 'info#policies',   as: 'policies'
  get '/faq',        to: 'info#faq',        as: 'faq'
  get '/developers', to: 'info#developers', as: 'developers'
  get '/credits',    to: 'info#credits',    as: 'credits'

  # Mounting API endpoint at /api/v1/
  mount API => '/'

  # Collections routes
  resources :collections, only: [:index, :show], param: 'category_id'

  # Blacklight routes
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  resource :catalog, only: [:index], as: 'catalog', path: 'search', controller: 'catalog', constraints: { id: /.*/ } do
    concerns :searchable
    concerns :range_searchable
  end

  # OAI endpoint
  match :oai, to: 'catalog#oai', via: [:post, :get], as: :oai_catalog

  # Redirect for old download links
  get '/download/fedora_content/download/:uri/:block/:filename', to: 'download#legacy_fedora_content', as: 'legacy_fedora_content',
    block: /(CONTENT|content)/, uri: /.+/, filename: /.+/

  # Routes for Solr Document using DOI as identifier
  #
  # Instead of specifying solr routes as:
  #   resources :solr_document, only: [:show], controller: 'catalog', path: 'doi', constraints: { id: /.*/ } do
  #     concerns :exportable
  #   end
  # Specifying routes using glob (*) in id param, this way slashes and period are accepted as part of the id.
  match 'doi/*id/download', to: 'download#content', via: :get,          as: 'content_download'
  match 'doi/*id',          to: 'catalog#show',     via: :get,          as: :solr_document

  mount Blacklight::Engine => '/'

  # RESTful routes for reindex API, working around Blacklight route camping
  delete '/solr_documents/:id', to: 'solr_documents#destroy'
  put '/solr_documents/:id', to: 'solr_documents#update'
  get '/solr_documents/:id', to: 'solr_documents#show'

  get '/download/download_log/:id', to: 'download#download_log', as: 'download_log'

  match '/statistics/detail_report',        to: 'statistics#detail_report',        via: [:get, :post]
  match '/statistics/all_author_monthlies', to: 'statistics#all_author_monthlies', via: [:get, :post]
  get '/statistics/generic_statistics',     to: 'statistics#generic_statistics'
  get '/statistics/send_csv_report',        to: 'statistics#send_csv_report'
  get '/statistics/school_statistics',      to: 'statistics#school_statistics'
  get '/statistics/common_statistics_csv',  to: 'statistics#common_statistics_csv'
  get '/statistics/statistic_res_list',     to: 'statistics#statistic_res_list'
  get '/statistics/total_usage_stats',      to: 'statistics#total_usage_stats'

  resource :agreement

  resources :uploads, only: [:index, :new, :create], path: 'upload'

  get 'myworks',             to: 'user#my_works'
  get 'account',             to: 'user#account'
  get 'unsubscribe_monthly', to: 'user#unsubscribe_monthly'

  get '/admin',                   to: 'admin#index',                 as: 'admin'

  namespace :admin do
    get 'author_affiliation_report/index'
    get 'author_affiliation_report/create'
    resources :request_agreements,  only: [:new, :create]
    resource  :alert_message,       only: [:edit, :update]
    resources :deposits,            only: [:index, :show]
    resources :agreements,          only: :index
    resources :email_preferences
    resources :email_author_reports,     only: [:new, :create]
    resources :usage_statistics_reports, only: [:new, :create] do
      get 'csv', on: :collection
    end
  end

  # Resque web interface, only administrators have access
  # Make sure that the resque user restriction below is AFTER `devise_for :users`
  resque_web_constraint = lambda do |request|
    current_user = request.env['warden'].user
    current_user.present? && current_user.respond_to?(:admin?) && current_user.admin?
  end
  constraints resque_web_constraint do
    mount Resque::Server.new, at: '/admin/resque'
  end

  get '/emails/get_csv_email_form', to: 'emails#get_csv_email_form'

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
