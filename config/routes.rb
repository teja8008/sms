Rails.application.routes.draw do
  root "home#show"
  get "employees", to: "home#show", format: false
  get "employees/:id", to: "home#show", constraints: { id: /[0-9]+/ }, format: false
  get "insights", to: "home#show", format: false
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get :analytics, to: "analytics#show"
      resources :employees, only: [ :index, :show ], constraints: { id: /[0-9]+/ } do
        patch :salary, on: :member, action: :update_salary
      end
    end
  end
end
