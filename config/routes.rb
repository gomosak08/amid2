Rails.application.routes.draw do
  # ================================
  # STATIC PAGES
  # ================================
  get "static/terms"
  get "static/privacy"
  get "static/contact"

  get "terms",   to: "static#terms"
  get "privacy", to: "static#privacy"
  get "contact", to: "static#contact"


  # ================================
  # PUBLIC PAGES
  # ================================
  get "services",  to: "services#index"
  get "packages",  to: "packages#index"
  get "surgeries", to: "surgeries#index"


  # ================================
  # PUBLIC APPOINTMENTS (BOOKING FLOW)
  # ================================
  resources :appointments, param: :token, only: %i[new create show edit update destroy] do
    collection do
      get  :find
      post :locate

      get  :booking_appointment

      get  :check_availability
      post :check_availability
    end
  end


  # ================================
  # ADMIN AREA
  # ================================
  namespace :admin do
    resources :users, except: [:show]
    resources :appointments do
      collection do
        get :available_fields
      end

      member do
        patch :cancel
        post :attach_results
        delete :remove_result
      end
    end

    resources :doctors do
      member do
        post   :mark_unavailable_day
        delete :clear_unavailable_day

        post   :mark_unavailable_range
        delete :clear_unavailable_range

        post   :create_time_block
        delete :destroy_time_block

        get    :calendar_events
        delete :destroy_unavailability
      end
    end

    resources :phone_bans, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member do
        patch :toggle_active
      end
    end

    resources :packages
  end


  # ================================
  # PUBLIC PACKAGES
  # ================================
  resources :packages, only: %i[index show]


  # ================================
  # AUTHENTICATION
  # ================================
  devise_for :users, skip: :registrations


  # ================================
  # HOMEPAGE
  # ================================
  root "home#index"
end
