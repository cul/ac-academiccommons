require 'resque/server'

Rails.application.routes.draw do
  concern :range_searchable, BlacklightRangeLimit::Routes::RangeSearchable.new
  # When we are doing local development, we use omniauth's built-in developer strategy with devise's built-in omniauth
  # engine. By not skipping :omniauth_callbacks in development, devise creates the routes /users/auth/developer and
  # /users/auth/developer/callback and configures them to use devise's omniauth_callbacks_controller actions.
  # In deployed environments, we use CUL's cas server (with the omniauth-cul gem) to authenticate users, with our
  #  custom defined routes and custom omniauth_callbacks_controller.
  # If we had not skipped the creation of these routes by devise, we would be able to authenticate users with our CAS
  # server, but Academic Commons would be vulnerable to CVE-2015-9284, because the devise routes allow clients to make
  # a GET request to users/auth/cas (instead of requiring a POST request).
  # We are trying to find a more elegant way to do this (and the documentation for omniauth implies that with v2, GET
  # requests should not be allowed, even if we have not gotten it to work), but this is a secure workaround for now.
  skip_omniauth_callbacks = Rails.env.development? ? [] : [:omniauth_callbacks]
  devise_for :users,
             controllers: { sessions: 'users/sessions', omniauth_callbacks: 'users/omniauth_callbacks' },
             skip: skip_omniauth_callbacks

  devise_scope :user do
    # Create the sign in and sign out routes (simply redirects to our auth endpoint), needed for redirecting on
    # cancancan access denied error
    delete 'sign_out', to: 'users/sessions#destroy', as: :destroy_user_session
    get 'sign_in', to: 'users/sessions#new', as: :new_user_session
    # Create the routes for omniauth auth and callback routes (unless doing local development) (see comment above)
    unless Rails.env.development?
      post 'users/auth/cas', to: 'users/omniauth_callbacks#passthru', as: :user_cas_omniauth_authorize
      get 'users/auth/cas/callback', to: 'users/omniauth_callbacks#cas', as: :user_cas_omniauth_callback
    end
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
  resources :collections, only: [:index, :show], param: 'category_id', path: 'explore'

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
  get '/download/fedora_content/download/:uri/:block/:filename', to: 'assets#legacy_fedora_content', as: 'legacy_fedora_content',
    block: /(CONTENT|content)/, uri: /.+/, filename: /.+/

  # Routes for Solr Document using DOI as identifier
  #
  # Instead of specifying solr routes as:
  #   resources :solr_document, only: [:show], controller: 'catalog', path: 'doi', constraints: { id: /.*/ } do
  #     concerns :exportable
  #   end
  # Specifying routes using glob (*) in id param, this way slashes and period are accepted as part of the id.
  match 'doi/*id/download', to: 'assets#download', via: :get, as: 'content_download'
  match 'doi/*id/embed',    to: 'assets#embed',    via: :get, as: 'embed'
  match 'doi/*id/captions', to: 'assets#captions', via: :get, as: 'captions_download'
  match 'doi/*id',          to: 'catalog#show',    via: :get, as: :solr_document

  mount Blacklight::Engine => '/'

  # RESTful routes for reindex API, working around Blacklight route camping
  delete '/solr_documents/:id', to: 'solr_documents#destroy'
  put '/solr_documents/:id', to: 'solr_documents#update'
  get '/solr_documents/:id', to: 'solr_documents#show'

  resource :agreement

  resources :uploads, only: [:index, :new, :create], path: 'upload'

  get '/detail/:slug', to: 'featured_searches#show', as: 'featured_search'

  get 'myworks',             to: 'user#my_works'
  get 'account',             to: 'user#account'
  get 'unsubscribe_monthly', to: 'user#unsubscribe_monthly'
  resources :users, only: [:show] do
    resource :token, only: [:create], module: :users
  end

  get '/admin',                   to: 'admin#index',                 as: 'admin'

  namespace :admin do
    get 'author_affiliation_report/index'
    get 'author_affiliation_report/create'
    resources :request_agreements,  only: [:new, :create]
    resource  :alert_message,       only: [:edit, :update]
    resource  :site_configuration,  only: [:edit, :update]
    resources :deposits,            only: [:index, :show]
    resources :downloads,           only: :index
    resources :agreements,          only: :index
    resources :email_preferences
    resources :email_author_reports,     only: [:new, :create]
    resources :usage_statistics_reports, only: [:new, :create] do
      post 'email', on: :collection
    end
    resources :featured_searches, except: :show
    resource :contact_authors, only: [:new, :create]
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

  get '/logs/all_author_monthly_reports_history', to: 'logs#all_author_monthly_reports_history'
  get '/logs/log_form',                           to: 'logs#log_form'
  get '/logs/ingest_history',                     to: 'logs#ingest_history'
  get '/download/download_log/:id',               to: 'logs#download_log', as: 'download_log'

  # Route used to render error page.
  get '/500', to: 'errors#internal_server_error'

  # Handle server redirects to /item/:id. This route will redirect those requests
  # to /catalog/:id.
  get '/item/:id',    to: 'catalog#legacy_show'
  get '/catalog/:id', to: 'catalog#legacy_show'

  # Temporary redirect for old deposit page url
  get '/deposit', to: redirect('/upload')
end
