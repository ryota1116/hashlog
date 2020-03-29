Rails.application.routes.draw do
  root 'static_pages#top'
  post "oauth/callback", to: "oauths#callback"
  get 'oauth/callback', to: 'oauths#callback'
  get "oauth/:provider", to: "oauths#oauth", as: :auth_at_provider
  delete 'logout', to: 'user_sessions#destroy'
  resources :users, only: %i[create edit update show destroy]
end
