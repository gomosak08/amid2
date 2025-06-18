Rails.application.routes.draw do
  # Static pages
  get "static/terms"
  get "static/privacy"
  get "static/contact"

  # Public service/resource listings
  get "services",  to: "services#index"
  get "packages",  to: "packages#index"
  get "surgeries", to: "surgeries#index"

  # Public routes for appointments (booking flow)
  resources :appointments, only: [ :new, :create, :show ] do
    collection do
      get  "booking_appointment"
      get  "find", to: "appointments#find"
      post "find", to: "appointments#locate"
      get  "check_availability", to: "appointments#check_availability"
    end
  end

  # Admin namespace
  namespace :admin do
    resources :doctors do
      member do
        post   "mark_unavailable_day"
        delete "clear_unavailable_day"
      end
    end

    resources :packages

    resources :appointments, only: [:new, :create] do
        collection { get :available_fields }
        member     { patch :cancel }
    end

      # Cancel a single appointment
      member do
        patch :cancel
      end
    end
  end

  # Cleanup: non-admin appointment management
  resources :packages, only: [ :index, :show ]
  resources :appointments, only: [ :edit, :update, :destroy ]
  post "check_availability", to: "appointments#check_availability"

  # Legacy static aliases (if you still need /terms, /privacy, /contact)
  get "terms",   to: "static#terms"
  get "privacy", to: "static#privacy"
  get "contact", to: "static#contact"

  # Devise for user authentication
  devise_for :users, skip: :registrations

  # Homepage
  root "home#index"
end
