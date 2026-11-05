Rails.application.routes.draw do
  resource :session, only: [:create, :destroy]
  resources :materials
  resources :movements, only: [:index, :create]
  get "up" => "rails/health#show", as: :rails_health_check
end