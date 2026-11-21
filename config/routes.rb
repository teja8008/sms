Rails.application.routes.draw do
  root "home#show"
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :employees, only: [ :index, :show ], constraints: { id: /[0-9]+/ } do
        patch :salary, on: :member, action: :update_salary
      end
    end
  end
end
