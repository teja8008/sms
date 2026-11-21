Rails.application.routes.draw do
  root "home#show"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :employees, only: [ :index, :show ], constraints: { id: /[0-9]+/ }
    end
  end
end
