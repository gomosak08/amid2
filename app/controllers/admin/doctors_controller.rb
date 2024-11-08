# app/controllers/admin/doctors_controller.rb
module Admin
  class DoctorsController < ApplicationController
    before_action :authenticate_user!   # Ensure the user is logged in
    before_action :require_admin        # Ensure only admins can access these actions
    before_action :set_doctor, only: [:edit, :update, :destroy]

    def index
      @doctors = Doctor.all
    end

    def new
      @doctor = Doctor.new
    end

    def create
      @doctor = Doctor.new(doctor_params)
      if @doctor.save
        redirect_to admin_doctors_path, notice: 'Doctor was successfully created.'
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @doctor.update(doctor_params)
        redirect_to admin_doctors_path, notice: 'Doctor was successfully updated.'
      else
        render :edit
      end
    end

    def destroy
      @doctor.destroy
      redirect_to admin_doctors_path, notice: 'Doctor was successfully deleted.'
    end

    private

    def set_doctor
      @doctor = Doctor.find(params[:id])
    end

    def doctor_params
      params.require(:doctor).permit(:name, :specialty, :email).tap do |whitelisted|
        if params[:doctor][:available_hours].present?
          # Convert available_hours to JSON if it's provided as a string
          whitelisted[:available_hours] = JSON.parse(params[:doctor][:available_hours]) rescue params[:doctor][:available_hours]
        end
      end
    end

    def require_admin
      unless current_user&.admin?
        redirect_to root_path, alert: "You are not authorized to access this page."
      end
    end
    def authenticate_user!
      if user_signed_in?
        super
      else
        # Redirect to a custom path if not signed in
        redirect_to your_custom_login_path, alert: "You need to sign in to access this page."
      end
    end
  end
end
