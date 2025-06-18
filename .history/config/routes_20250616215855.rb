# config/routes.rb

Rails.application.routes.draw do
  get "static/terms"
  get "static/privacy"
  get "static/contact"
  get "services", to: "services#index"
  get "packages", to: "packages#index"
  get "surgeries", to: "surgeries#index"

  # Public routes for appointments
  resources :appointments, only: [ :new, :create, :show ] do
    collection do
      get "booking_appointment"
      get "find", to: "appointments#find"
      post "find", to: "appointments#locate"
      get "appointments/check_availability", to: "appointments#check_availability", as: :check_availability
    end
  end

  # ✅ Combine all admin routes here
  namespace :admin do
    resources :doctors do
      member do
        post "mark_unavailable_day"
        delete "clear_unavailable_day"
      end
    end

    resources :packages

    resources :appointments, only: [:new, :create] do
        patch "cancel"
      end

      collection do
        get :available_fields  
      end
    end
  end

  # Redundant appointments routes (clean up as needed)
  resources :packages
  resources :appointments, only: [ :edit, :update, :destroy ]
  post "check_availability", to: "appointments#check_availability"
  get "terms",   to: "static#terms"
  get "privacy", to: "static#privacy"
  get "contact", to: "static#contact"

  # Devise
  devise_for :users, skip: :registrations

  # Root
  root "home#index"
end
