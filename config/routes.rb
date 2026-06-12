Rails.application.routes.draw do
  root "static_pages#top"
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
  get "/typing", to: "typing#show"
  get "/typing/result", to: "typing#result"
  post "/typing/results", to: "typing#save_result"

  get "/typing/histories", to: "typing_histories#index"

  post "/articles", to: "articles#create"

  get "/terms", to: "static_pages#terms"
  get "/privacy", to: "static_pages#privacy"
  
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
