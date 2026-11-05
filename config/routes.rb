Rails.application.routes.draw do
  root "inventario#index"
  get "login", to: "sesiones#new"
  post "login", to: "sesiones#create"
  delete "logout", to: "sesiones#destroy"
  get "inventario", to: "inventario#index"
  get "conciliacion", to: "conciliacion#index"
  resources :movimientos, only: [:new, :create]

  resource :session, only: [:create, :destroy]
  resources :materials do
    get :nivel, on: :member
  end
  resources :movements, only: [:index, :create]
  get "up" => "rails/health#show", as: :rails_health_check
end