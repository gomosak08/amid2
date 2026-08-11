Rails.application.routes.draw do
  namespace :api do
    namespace :internal do
      namespace :v1 do
        resources :appointments, only: %i[index show create update] do
          member do
            patch :clinical_status
            post :cancel
          end
        end

        resources :packages, only: %i[index show]
        resources :doctors, only: %i[index show]

        get "doctors/:doctor_id/availability",
            to: "doctor_availability#show",
            as: :doctor_availability

        get "doctors/:doctor_id/calendar",
            to: "doctor_calendar#show",
            as: :doctor_calendar

        scope "doctors/:doctor_id" do
          resources :time_blocks,
                    controller: "doctor_time_blocks",
                    only: %i[index show create update destroy]
        end
      end
    end
  end


  namespace :api do
    namespace :webhooks do
      get  :whatsapp, to: "whatsapp#verify"
      post :whatsapp, to: "whatsapp#receive"
    end
  end

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
    resources :users, except: [ :show ]
    resources :statistics, only: [ :index ]
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

        post   :create_unified_block

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
    resources :specialties
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
  # WHATSAPP WEBHOOK
  # ================================
  post "/webhooks/whatsapp", to: "webhooks#whatsapp"
  get  "/webhooks/whatsapp", to: "webhooks#verify"

  # ================================
  # HOMEPAGE
  # ================================
  root "home#index"
end
