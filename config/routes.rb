# config/routes.rb

Rails.application.routes.draw do
  # Public routes for appointments, including a custom route for booking_appointment
  resources :appointments, only: [:new, :create, :show] do
    collection do
      get 'booking_appointment'
      get 'find', to: 'appointments#find' # GET route to display the form
      post 'find', to: 'appointments#locate' 
      get 'appointments/check_availability', to: 'appointments#check_availability', as: :check_availability
  
      #resources :appointments
    end
  end

  # Admin routes, restricted by `before_action` in controllers
  namespace :admin do
    resources :doctors do
      member do
        post 'mark_unavailable_day'
        delete 'clear_unavailable_day'
      end
    end
    resources :packages
    resources :appointments do
      member do
        patch 'cancel' # Define the cancel route for appointments
      end
    end
  end

  # Public routes for packages
  resources :packages, only: [:index, :show]
  resources :appointments, only: [:edit, :update, :destroy]
  post 'check_availability', to: 'appointments#check_availability'

  # Devise routes for user authentication, skipping the `registrations` routes
  devise_for :users, skip: :registrations

  # Root path for public access
  root 'packages#index'
end
