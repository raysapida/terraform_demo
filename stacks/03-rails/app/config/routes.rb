Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resources :uploads, only: %i[index create]
  root "uploads#index"
end
