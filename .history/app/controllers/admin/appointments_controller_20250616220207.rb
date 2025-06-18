class Admin::AppointmentsController < ApplicationController
    before_action :set_appointment, only: [ :show, :edit, :update, :cancel ]
    before_action :authenticate_user!
    before_action :require_admin_or_secretary

    def set_locale
      I18n.locale = :es
    end

    def cancel
      id = @appointment.google_calendar_id
      # Attempt to eliminate the Google Calendar event
      eliminate_google_calendar_event(id) if id.present?

      # Update the appointment status to "canceled_by_client" and set the canceled_at timestamp
      if @appointment.update(status: "canceled_by_Admin", canceled_at: Time.current)
        flash[:notice] = "Appointment successfully canceled."
        redirect_to admin_appointments_path
      else
        flash[:alert] = "Failed to cancel the appointment. Please try again."
        redirect_to admin_appointments_path
      end
    end


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

    def index
        if params[:date].present?
          selected_date = Date.parse(params[:date]) rescue nil
          if selected_date
            @appointments = Appointment.where(start_date: selected_date.all_day).order(:start_date)
          else
            @appointments = Appointment.none
            flash.now[:alert] = "Invalid date format."
          end
        else
          @appointments = Appointment.none # Default: do not show all appointments
        end
    end

    def destroy
      @appointment = Appointment.find(params[:id])
      if @appointment.destroy
        redirect_to admin_appointments_path, notice: "Appointment successfully deleted."
      else
        redirect_to admin_appointments_path, alert: "Failed to delete appointment."
      end
    end


    def update
        @appointment = Appointment.find(params[:id])

        if appointment_params[:status] == "Canceled_by_admin"
          id = @appointment.google_calendar_id
          eliminate_google_calendar_event(id)
        end
        if @appointment.update(appointment_params)
          redirect_to admin_appointment_path(@appointment), notice: "Appointment successfully updated."
        else
          render :edit, alert: "Failed to update appointment."
        end
    end

    def new
      @packages = Package.all
    end

    # Steps 2 & 3: doctor/date form, then available-times append
    def available_fields
      @package          = params[:package_id]
      @doctor_id        = params[:doctor_id]
      @appointment_date = params[:appointment_date]
      @doctors          = Doctor.all
      @duration         = @package.duration.to_i
      @appointment      = Appointment.new

      streams = [
        turbo_stream.replace(
          "appointment_form",
          partial: "admin/appointments/doctor_date_form",
          locals: {
            package:          @package,
            doctors:          @doctors,
            doctor_id:        @doctor_id,
            appointment_date: @appointment_date
          }
        )
      ]

      if @doctor_id.present? && @appointment_date.present?
        @available_times = fetch_available_times(
                             Doctor.find(@doctor_id),
                             @appointment_date,
                             @duration
                           )

        streams << turbo_stream.append(
          "appointment_steps",
          partial: "admin/appointments/available_times_form",
          locals: {
            appointment:      @appointment,
            package:          @package,
            doctor_id:        @doctor_id,
            appointment_date: @appointment_date,
            available_times:  @available_times,
            duration:         @duration
          }
        )
      end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: streams }
        format.html           { render :new }
      end
    end

    # Final booking
    def create
      @appointment = Appointment.new(appointment_params)
      if @appointment.save
        render turbo_stream: turbo_stream.replace(
          "appointment_form",
          partial: "admin/appointments/confirmation",
          locals: { appointment: @appointment }
        )
      else
        # handle errors…
      end
    end

    private
    def set_appointment
      @appointment = Appointment.find_by(id: params[:id])
      unless @appointment
        redirect_to admin_appointments_path, alert: "Appointment not found."
      end
    end

    def appointment_params
        params.require(:appointment).permit(:name, :age, :email, :phone, :sex, :doctor_id, :package_id, :status, :duration, :start_date)
    end

    def require_admin_or_secretary
      unless current_user&.admin? || current_user&.secretary?
        redirect_to root_path, alert: "No tienes permiso para acceder a esta sección."
      end
    end

    def google_credentials
        client_id = Rails.application.credentials.dig(:google, :client_id)
        client_secret = Rails.application.credentials.dig(:google, :client_secret)
        access_token = Rails.application.credentials.dig(:google, :access_token)
        refresh_token = Rails.application.credentials.dig(:google, :refresh_token)


        credentials = Signet::OAuth2::Client.new(
          client_id: client_id,
          client_secret: client_secret,
          token_credential_uri: "https://oauth2.googleapis.com/token",
          refresh_token: refresh_token,
          authorization_uri: "https://accounts.google.com/o/oauth2/auth",
          scope: "https://www.googleapis.com/auth/calendar",
          redirect_uri: "http://localhost:3000"
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
        calendar.delete_event("primary", event_id)
        puts "Event with ID #{event_id} was successfully deleted."
      rescue Google::Apis::AuthorizationError => e
        puts "Authorization error: #{e.message}"
      rescue Google::Apis::ClientError => e
        puts "Failed to delete event: #{e.message}"
      end
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
          start_time_str, end_time_str = times.split("-")
          start_time = Time.zone.parse("#{selected_date} #{start_time_str}")
          end_time = Time.zone.parse("#{selected_date} #{end_time_str}")

          # Fetch all existing appointments for the doctor on the selected date
          existing_appointments = Appointment.where(
            doctor_id: doctor.id,
            start_date: selected_date.all_day
          ).where.not(status: "Scheduled").pluck(:start_date, :end_date)


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
end
