CulBlacklightAc2::Application.routes.draw do
  Blacklight.add_routes(self)

  root :to => "catalog#index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  
  resources :email_preferences, :reports
  
  match '/download/fedora_content/:download_method/:uri/:block/:filename', :to => 'download#fedora_content', :as => "fedora_content",
    :block => /(DC|CONTENT|SOURCE)/,
    :uri => /.+/, :filename => /.+/, :download_method => /(download|show|show_pretty)/
  match '/access_denied', :to => 'application#access_denied', :as => 'access_denied'
  
  match '/ingest_monitor/:id', :to => 'ingest_monitor#index', :as => 'ingest_monitor'
  
  match '/statistics/search_history', :to => 'statistics#search_history', :as => 'search_statistics'
  
  match '/deposit', :to => 'deposit#index', :as => 'deposit'
  
  match '/admin', :to => 'admin#index', :as => 'admin'
  match '/admin/deposits/:id', :to => 'admin#show_deposit', :as => 'show_deposit'
  
  match ':controller/:action'
  match ':controller/:action/:id'
  match ':controller/:action/:id.:format'
  
  match '/catalog/browse/departments', :to => 'catalog#browse_department', :as => 'departments_browse'
  match '/catalog/browse/subjects', :to => 'catalog#browse_subject', :as => 'subjects_browse'
  match '/catalog/browse/departments/:id', :to => 'catalog#browse_department', :as => 'department_browse'
  match '/catalog/browse/subjects/:id', :to => 'catalog#browse_subject', :as => 'subject_browse'
  
  match '/item/:id', :to => 'catalog#show', :as => 'catalog_item'
  
  match '/login',          :to => 'user_sessions#new',          :as => 'new_user_session'
  match '/wind_logout',    :to => 'user_sessions#destroy',      :as => 'destroy_user_session'
  # match 'account',        :to => 'application#account',     :as => 'edit_user_registration'
  
end
