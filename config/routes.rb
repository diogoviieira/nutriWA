Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Guest flow
  root "nutritionists#index"
  resources :nutritionists, only: [ :index, :show ] do
    member do
      get :requests
    end
  end
  resources :appointment_requests, only: [ :create ]

  # API for React (Nutritionist panel)
  namespace :api do
    resources :appointment_requests, only: [] do
      member do
        patch :accept
        patch :reject
      end
    end
    resources :nutritionists, only: [] do
      resources :appointment_requests, only: [ :index ]
    end
  end
end
