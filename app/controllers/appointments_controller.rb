# app/controllers/appointments_controller.rb
require 'google/apis/calendar_v3'

class AppointmentsController < ApplicationController
  before_action :set_appointment, only: [:show, :destroy]

  def locate
    @appointment = Appointment.find_by(unique_code: params[:unique_code])
    if @appointment
      redirect_to edit_appointment_path(@appointment)
    else
      flash[:alert] = "Appointment not found. Please check your code."
      render :find
    end
  end

  def edit
    @appointment = Appointment.find(params[:id])
  end


  def destroy
    id = @appointment.google_calendar_id
    eliminate_google_calendar_event(id)
    @appointment.update(status: "canceled_by_client", canceled_at: Time.current)
    flash[:notice] = "Appointment successfully canceled."
    redirect_to root_path
  end

  def index
    redirect_to new_appointment_path
  end

  def new
    @appointment = Appointment.new # Initialize a new appointment
    
    @doctors = Doctor.all # Fetch all doctors for selection
    @doctor_id = params[:doctor_id]
    @appointment_date = params[:appointment_date]
    @available_times = []
    @package = Package.find_by(id: params[:package_id])
    @duration = @package.duration.to_i
    unless @package
      flash[:alert] = "Invalid or missing package."
      redirect_to root_path and return
    end
  
    @duration = @package.duration 
    # Fetch available times if doctor and date are provided
    #puts "this are the params #{params}"
    if @doctor_id.present? && @appointment_date.present?
      doctor = Doctor.find_by(id: @doctor_id)
      if doctor
        @available_times = fetch_available_times(doctor, @appointment_date, @duration)
        puts "this are the available times #{@available_times}"
        if @available_times.empty?
          flash.now[:alert] = "No available times for the selected date."
        end
      end
    end
  
    respond_to do |format|
      format.html # For the initial page load
      format.turbo_stream # For dynamic Turbo Frame updates
    end
  end

  def create
    puts "Start creating #{params}"
    @doctors = Doctor.all
    @package = Package.find(params[:appointment][:package_id])
    start_date = Time.zone.parse(params[:appointment][:start_date])
    @duration = @package.duration.to_i
    #duration_minutes = @package.duration.to_i
    #puts  "duration #{duration_minutes}"
    #puts start_date
    end_date = start_date + @duration.to_i.minutes
    doctor_id = appointment_params[:doctor_id]
    doctor = Doctor.find(doctor_id).name
    
    puts "start date: #{start_date} duration: #{@duration}"
    # Verify reCAPTCHA before proceeding with the booking
    if verify_recaptcha(model: @appointment) # `verify_recaptcha` automatically validates the reCAPTCHA response
      if time_slot_available?(doctor_id, start_date)
        status = "Scheduled"
        @appointment = Appointment.new(appointment_params.merge(end_date: end_date, status: status))
        id_calendar = create_google_calendar_event(@appointment, @package, doctor,doctor_id)
        puts params
        @appointment.update(google_calendar_id: id_calendar)

        Rails.logger.debug "Start Date: #{start_date}"
        if @appointment.save
          redirect_to @appointment, notice: 'Appointment was successfully created.'
        else
          id = @appointment.google_calendar_id
          eliminate_google_calendar_event(id)
          puts "This is the id #{id}"
          Rails.logger.debug @appointment.errors.full_messages.join(", ")
          render :new
        end
      else
        # If the time slot is taken, re-render the `new` view with an error
        flash.now[:alert] = "The selected time is no longer available. Please choose a different time."
        @available_times = fetch_available_times(Doctor.find(doctor_id), start_date.to_date, @duration)
        render :new
      end
    else
      # If reCAPTCHA validation fails, add a flash message to prompt the user
      flash.now[:alert] = "Please complete the CAPTCHA to confirm you are human."
      # Preserve available times and doctors list, and re-render the form with all filled data intact
      @available_times = fetch_available_times(Doctor.find(doctor_id), start_date.to_date, @duration)
      render :new
    end
  end

  def show
    @appointment = Appointment.find(params[:id])
    Rails.logger.debug "Appointment: #{@appointment.inspect}"
    Rails.logger.debug "Package: #{@appointment.package.inspect}"
  end

  def check_availability
    @doctor = Doctor.find(params[:doctor_id])
    @start_date_available = params[:start_date]
    @available_times = fetch_available_times(@doctor, @start_date_available, @duration)
  
    respond_to do |format|
      format.js { render partial: 'appointments/available_form', locals: { available_times: @available_times, timezone: "America/Mexico_City" } }
    end
  end

  

  private

  def appointment_params
    params.require(:appointment).permit(:name, :age, :email, :phone, :sex, :doctor_id, :package_id, :status, :duration, :start_date, :google_calendar_id)
    #permit(:package_id, :doctor_id, :duration, :start_date, :name, :age, :phone, :google_calendar_id)
  end

  def time_slot_available?(doctor_id, start_date)
    Appointment.where(doctor_id: doctor_id, start_date: start_date).empty?
  end

  def set_appointment
    @appointment = Appointment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to appointments_path, alert: "Appointment not found."
  end

  def fetch_available_times(doctor, selected_date, duration)
    selected_date = Date.parse(selected_date) if selected_date.is_a?(String)
    Time.zone = "America/Mexico_City"
    
    Time.use_zone("America/Mexico_City") do
      day_name = selected_date.strftime("%A")
      available_times = []
      current_time = Time.zone.now
  
      # Check for dummy appointments
      dummy_appointments_count = Appointment.where(
        doctor_id: doctor.id,
        start_date: selected_date.all_day,
        dummy: true
      ).count
      return [] if dummy_appointments_count > 0
  
      # Check doctor's available hours
      data = doctor.available_hours[day_name]
      times = data.first unless data.empty?
      if times
        start_time_str, end_time_str = times.split('-')
        start_time = Time.zone.parse("#{selected_date} #{start_time_str}")
        end_time = Time.zone.parse("#{selected_date} #{end_time_str}")
  
        # Fetch all existing appointments for the doctor on the selected date
        existing_appointments = Appointment.where(
          doctor_id: doctor.id,
          start_date: selected_date.all_day
        ).pluck(:start_date, :end_date)
  
        while start_time < end_time
          if start_time >= current_time
            # Check if the time slot overlaps with any existing appointment
            overlapping = existing_appointments.any? do |appt_start, appt_end|
              start_time < appt_end && (start_time + duration.minutes) > appt_start
            end
            
            # Add the time slot if it doesn't overlap
            available_times << start_time unless overlapping
          end
  
          start_time += duration.minutes
        end
      end
  
      available_times
    end
  end
  
  
  def create_google_calendar_event(appointment, package, doctor,doctor_id)
    # Initialize Google Calendar API client
    calendar = Google::Apis::CalendarV3::CalendarService.new
    credentials = google_credentials # Ensure this returns the full client object
  
    # Set the full credentials object for authorization
    calendar.authorization = credentials
  

    # Prepare event details
    event = Google::Apis::CalendarV3::Event.new(
      summary: "#{package.name} con #{doctor}",
      description: "Nombre: #{appointment.name} \n Telefono: #{appointment.phone}",
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: (appointment.start_date).iso8601,
        time_zone: 'America/Mexico_City'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.end_date.iso8601,
        time_zone: 'America/Mexico_City'
      ),
      color_id: doctor_id
    )
  
    # Attempt to insert the event
    begin
      created_event = calendar.insert_event('primary', event)
      id = created_event.id
      puts "Event created successfully! Link: #{created_event.html_link}"
    rescue Google::Apis::AuthorizationError => e
      puts "Authorization error: #{e.message}"
    end
    id
  end
  
  def google_credentials

    client_id = Rails.application.credentials.dig(:google, :client_id)
    client_secret = Rails.application.credentials.dig(:google, :client_secret)
    access_token = Rails.application.credentials.dig(:google, :access_token)
    refresh_token = Rails.application.credentials.dig(:google, :refresh_token)


    credentials = Signet::OAuth2::Client.new(
      client_id: client_id,
      client_secret: client_secret,
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      refresh_token: refresh_token,
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: 'https://www.googleapis.com/auth/calendar',
      redirect_uri: 'http://localhost:3000' 
    )

     # Refresh the access token if expired
    if credentials.expired? || credentials.access_token.nil?
      credentials.refresh!
      puts "Token refreshed successfully: #{credentials.access_token}"
      # Optional: Save the new access token if you need to use it later
      Rails.application.credentials.google[:access_token] = credentials.access_token
    end

    credentials
  end

  def eliminate_google_calendar_event(id)
    # Initialize the Calendar service
    calendar = Google::Apis::CalendarV3::CalendarService.new

    # Set up OAuth2 credentials (use your method for obtaining credentials)
    credentials = google_credentials # Replace this with your actual credentials method
    calendar.authorization = credentials

    # Event ID you want to delete
    event_id = id

    # Delete the event
    begin
      calendar.delete_event('primary', event_id)
      puts "Event with ID #{event_id} was successfully deleted."
    rescue Google::Apis::AuthorizationError => e
      puts "Authorization error: #{e.message}"
    rescue Google::Apis::ClientError => e
      puts "Failed to delete event: #{e.message}"
    end
  end 
end
