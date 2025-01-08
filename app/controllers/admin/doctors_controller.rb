# app/controllers/admin/doctors_controller.rb
module Admin
  class DoctorsController < ApplicationController
    before_action :authenticate_user!   # Ensure the user is logged in
    before_action :require_admin        # Ensure only admins can access these actions
    before_action :set_doctor, only: [:edit, :update, :destroy,:mark_unavailable_day]

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
      @doctor = Doctor.find(params[:id])
      @doctor.available_hours ||= default_hours
    end

    def update
      Rails.logger.debug "Processed Params: #{doctor_params}"
    
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


    def mark_unavailable_day
      selected_date = Date.parse(params[:date]) rescue nil
      duration = 30 # Assuming a 30-minute duration for each slot; adjust as needed

      if selected_date
        create_dummy_appointments(@doctor, selected_date, duration)
        redirect_to admin_doctors_path, notice: "Doctor marked as unavailable for #{selected_date}."
      else
        redirect_to admin_doctors_path, alert: "Invalid date selected."
      end
    end

    def clear_unavailable_day
      selected_date = Date.parse(params[:date]) rescue nil
    
      # Debugging output
      puts "Doctor ID in params: #{params[:id]}"
      puts "@doctor: #{Doctor.find(params[:id]).inspect}"
      @doctor = Doctor.find(params[:id])

      if selected_date
        dummy_appointments = Appointment.where(
          doctor: @doctor,
          start_date: selected_date.all_day,
          name: "Unavailable"
        )
    
        if dummy_appointments.exists?
          dummy_appointments.destroy_all
          redirect_to admin_doctors_path, notice: "Unavailable day cleared for #{@doctor.name} on #{selected_date}."
        else
          redirect_to admin_doctors_path, alert: "No dummy appointments found for #{@doctor.name} on #{selected_date}."
        end
      else
        redirect_to admin_doctors_path, alert: "Invalid date selected."
      end
    end

    def default_hours
      {
        "Monday" => "09:00-17:00",
        "Tuesday" => "09:00-17:00",
        "Wednesday" => "09:00-17:00",
        "Thursday" => "09:00-17:00",
        "Friday" => "09:00-17:00",
        "Saturday" => "09:00-17:00",
        "Sunday" => "09:00-17:00"
      }
    end

    private

    def fetch_available_times(doctor, selected_date, duration)
      # Ensure `selected_date` is parsed as a Date object
      selected_date = Date.parse(selected_date) if selected_date.is_a?(String)
      
      # Use Mexico City timezone for all time calculations within this block
      Time.use_zone("America/Mexico_City") do
        day_name = selected_date.strftime("%A") # e.g., "Monday"
        available_times = []
        current_time = Time.zone.now
      
        if doctor.available_hours && doctor.available_hours[day_name]
          doctor.available_hours[day_name].each do |range|
            start_time_str, end_time_str = range.split('-')
            start_time = Time.zone.parse("#{selected_date} #{start_time_str}")
            end_time = Time.zone.parse("#{selected_date} #{end_time_str}")
      
            # Generate slots within the available range
            while start_time < end_time
              available_times << start_time if start_time >= current_time
              start_time += duration.minutes
            end
          end
        end
    
        # Fetch booked and dummy appointment times for the doctor on the selected date
        booked_times = Appointment.where(doctor_id: doctor.id, start_date: selected_date.all_day)
                                  .where.not(name: "Unavailable") # Exclude dummy appointments
                                  .pluck(:start_date)
    
        # If there are dummy appointments for the day, return an empty array to indicate it's fully booked
        dummy_appointments_count = Appointment.where(doctor_id: doctor.id, start_date: selected_date.all_day, name: "Unavailable").count
        return [] if dummy_appointments_count > 0
    
        # Filter out any available times that overlap with booked appointments
        available_times.reject { |time| booked_times.include?(time) }
      end
    end

    def create_dummy_appointments(doctor, selected_date, duration)
      available_times = fetch_available_times(doctor, selected_date, duration)
      puts available_times.first
      #available_times.each do |time_slot|
        Appointment.create!(
          doctor: doctor,
          package_id: 1,
          name: "dia_libre",
          age: "0",
          sex: "dia_libre",
          email: "dia_libre",
          phone: 0,
          start_date: available_times.first,
          end_date: available_times.first + 720.minutes,
          dummy: true # Mark this appointment as a dummy to indicate unavailability
        )

    end


    def set_doctor
      @doctor = Doctor.find_by(id: params[:id])
      unless @doctor
        redirect_to admin_doctors_path, alert: "Doctor not found."
      end
    end

    def doctor_params
      params.require(:doctor).permit(:name, :specialty, :email).tap do |whitelisted|
        if params[:doctor][:available_hours].present?
          whitelisted[:available_hours] = params[:doctor][:available_hours].transform_values do |times|
            start_time, end_time = times
            if start_time.present? && end_time.present?
              ["#{start_time}-#{end_time}"] # Format as "start-end"
            else
              [] # Default to an empty array if times are incomplete
            end
          end.to_json
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
        redirect_to root_path, alert: "You need to sign in to access this page."
      end
    end
  end
end
