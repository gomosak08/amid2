class Admin::AppointmentsController < ApplicationController
    before_action :authenticate_user!   # Ensure only logged-in users can access
    before_action :require_admin        # Ensure only admins can access
    before_action :set_appointment, only: [:show, :edit, :update, :cancel]

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

        if appointment_params[:status] == 'Canceled_by_admin'
          id = @appointment.google_calendar_id
          eliminate_google_calendar_event(id)
        end
        if @appointment.update(appointment_params)
          redirect_to admin_appointment_path(@appointment), notice: 'Appointment successfully updated.'
        else
          render :edit, alert: 'Failed to update appointment.'
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

    def require_admin
        unless current_user&.admin?
          redirect_to root_path, alert: "You are not authorized to access this page."
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
