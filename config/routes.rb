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
  # resources :appointments, param: :token, only: %i[index new create show edit update destroy]
  resources :appointments, param: :token, only: %i[new create show edit update destroy] do
    collection do
      get  :find    # muestra el formulario para ingresar el código
      post :locate  # procesa el código y redirige
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
  end

  namespace :admin do
    resources :appointments, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
      collection do
        get :available_fields
      end
    member do
      patch :cancel   # ✅ esto te crea cancel_admin_appointment_path(:id)
    end
    end
  end

  # Cleanup: non-admin appointment management
  resources :packages, only: [ :index, :show ]
  namespace :admin do
    resources :packages
  end
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
