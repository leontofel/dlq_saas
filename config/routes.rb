Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"
  get "/overview", to: "dashboard#show", as: :overview
  get "/ready", to: "api/system#ready", defaults: { format: :json }

  get "/login", to: "auth_pages#login", as: :login_page
  get "/signup", to: "auth_pages#sign_up", as: :signup_page

  post "/login", to: "sessions#create", as: :login
  post "/signup", to: "registrations#create", as: :signup
  delete "/logout", to: "sessions#destroy", as: :logout

  resources :organizations, only: %i[index show create] do
    resources :organization_memberships, only: :create
    resources :projects, only: %i[index create]
  end

  resources :projects, only: :show do
    resources :project_api_keys, only: :create do
      patch :revoke, on: :member
    end
    resources :sources, only: %i[index create]
    resources :redaction_rules, only: %i[index create]
    resources :failed_messages, only: %i[index show] do
      patch :status, on: :member, to: "failed_messages#update_status"
      resources :message_notes, only: :create
    end
  end

  namespace :api, defaults: { format: :json } do
    post "/login", to: "auth#login"
    post "/signup", to: "auth#sign_up"
    get "/ready", to: "system#ready"
    resources :failed_messages, only: :create
  end
end
