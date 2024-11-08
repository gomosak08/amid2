# config/routes.rb
Rails.application.routes.draw do
  resources :appointments, only: [:new, :create, :show] do
    collection do
      get 'booking_appointment'  # Defines a route for booking_appointment within appointments
    end
  end
  
  get "appointments/new"
  get "appointments/create"
  # Admin routes, restricted by before_action in controllers
  namespace :admin do
    get "doctors/new"
    get "doctors/create"
    get "doctors/index"
    get "doctors/edit"
    get "doctors/update"
    get "doctors/destroy"
    resources :packages
    resources :appointments
    resources :doctors
    resources :users, only: [:index, :edit, :update, :destroy]
    
  end

  # Public routes, no login required
  resources :packages #, only: [:index, :show]
  resources :appointments, only: [:new, :create, :show]

  # Devise routes for admins only
  devise_for :users

  # Root path for public access
  root 'packages#index'
end
