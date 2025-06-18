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
    @appointment      = Appointment.new
    @doctors          = Doctor.all
    @doctor_id        = params[:doctor_id]
    @appointment_date = params[:appointment_date]
    @time_slot        = params[:time_slot]
    @available_times  = []
    @duration         = 0

    if params[:package_id].present?
      @package  = Package.find(params[:package_id])
      @duration = @package.duration.to_i

      # Only fetch times if we've also got doctor+date
      if @doctor_id.present? && @appointment_date.present? && @time_slot.blank?
        doctor = Doctor.find_by(id: @doctor_id)
        @available_times = fetch_available_times(doctor, @appointment_date, @duration) if doctor
      end
    else
      # For the initial HTML load, show all packages
      @packages = Package.all
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        streams = []

        # Step 2: after picking package → show doctor+date
        if params[:package_id].present? && @doctor_id.blank?
          streams << turbo_stream.replace(
            "doctor_date_frame",
            partial: "admin/appointments/doctor_date_form",
            locals: {
              package:          @package,
              doctors:          @doctors,
              doctor_id:        @doctor_id,
              appointment_date: @appointment_date
            }
          )

        # Step 3: after picking doctor+date → show times
        elsif @doctor_id.present? && @appointment_date.present? && @time_slot.blank?
          streams << turbo_stream.replace(
            "available_times_frame",
            partial: "admin/appointments/available_times_form",
            locals: {
              package:          @package,
              doctors:          @doctors,
              doctor_id:        @doctor_id,
              appointment_date: @appointment_date,
              available_times:  @available_times,
              duration:         @duration
            }
          )

        # Step 4: after picking time → show client data form
        elsif @time_slot.present?
          streams << turbo_stream.replace(
            "client_data_frame",
            partial: "admin/appointments/client_data_form",
            locals: {
              appointment:      @appointment,
              package:          @package,
              doctor_id:        @doctor_id,
              appointment_date: @appointment_date,
              time_slot:        @time_slot
            }
          )
        end

        render turbo_stream: streams
      end
    end
  end



  def available_fields
    @package          = Package.find(params[:package_id])
    @doctor_id        = params[:doctor_id]
    @appointment_date = params[:appointment_date]
    @doctors          = Doctor.all
    @duration         = @package.duration.to_i
    @appointment      = Appointment.new

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "doctor_date_frame",
          partial: "admin/appointments/doctor_date_form",
          locals: {
            package:          @package,
            doctors:          @doctors,
            doctor_id:        @doctor_id,
            appointment_date: @appointment_date
          }
        )
      end
    end
  end



  def create
    @package = Package.find(params[:appointment][:package_id])

    @appointment = Appointment.new(
      appointment_params.merge(
        status:   "Scheduled",
        end_date: Time.zone.parse(params[:appointment][:start_date]) +
                  @package.duration.to_i.minutes
      )
    )

    respond_to do |format|
      format.html do
        @appointment = Appointment.new(appointment_params.merge(end_date: end_date, status: status))

        id_calendar = create_google_calendar_event(@appointment, @package, doctor.name, doctor_id)
        @appointment.google_calendar_id = id_calendar

        if @appointment.save
          redirect_to appointment_path(@appointment), notice: "Cita creada con éxito."
        else
          eliminate_google_calendar_event(id_calendar)
          flash.now[:alert] = "Error al agendar. Por favor revisa los datos."
          render :new, status: :unprocessable_entity

        end
      end

      format.turbo_stream do
        if @appointment.save
          # Tell Turbo to navigate to the public appointment#show page
          render turbo_stream: turbo_stream.redirect_to(
            appointment_path(@appointment)
          )
        else
          render turbo_stream: turbo_stream.replace(
            "client_data_frame",
            partial: "admin/appointments/client_data_form",
            locals: {
              appointment:      @appointment,
              package:          @package,
              doctor_id:        params[:appointment][:doctor_id],
              appointment_date: params[:appointment][:start_date].to_date.iso8601,
              time_slot:        params[:appointment][:start_date]
            }
          ), status: :unprocessable_entity
        end
      end
    end
  end






  def create
    @doctors = Doctor.all
    @package = Package.find_by(id: params[:appointment][:package_id])

    if @package.nil?
      flash[:alert] = "The selected package could not be found."
      redirect_to root_path and return
    end

    start_date = Time.zone.parse(params[:appointment][:start_date])
    @duration = @package.duration.to_i
    end_date = start_date + @duration.to_i.minutes

    doctor_id = appointment_params[:doctor_id]
    doctor = Doctor.find_by(id: doctor_id)

    unless doctor
      flash[:alert] = "Selected doctor not found."
      redirect_to root_path and return
    end

    g_recaptcha_token = params[:appointment][:recaptcha_token]

    Rails.logger.info "==========================="
    Rails.logger.info "Received reCAPTCHA Token: #{g_recaptcha_token.inspect}"
    Rails.logger.info "==========================="

    unless verify_recaptcha(action: "homepage", minimum_score: 0)
      Rails.logger.info "==========================="
      Rails.logger.info "nel perro"
      Rails.logger.info "==========================="
      flash[:alert] = "reCAPTCHA verification failed. Please try again."
      redirect_to root_path and return
    end

    unless time_slot_available?(doctor_id, start_date)
      flash.now[:alert] = "The selected time is no longer available. Please choose a different time."
      @available_times = fetch_available_times(doctor, start_date.to_date, @duration)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "appointment_form",
            partial: "appointments/form",
            locals: { appointment: @appointment }
          )
        end
        format.html { render :new, status: :unprocessable_entity }
      end
      return
    end

    status = "Scheduled"
    @appointment = Appointment.new(appointment_params.merge(end_date: end_date, status: status))

    id_calendar = create_google_calendar_event(@appointment, @package, doctor.name, doctor_id)
    @appointment.google_calendar_id = id_calendar

    if @appointment.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "appointment_form",
            partial: "appointments/success",
            locals: { appointment: @appointment }
          )
        end
        format.html { redirect_to @appointment, notice: "Appointment was successfully created." }
      end
    else
      eliminate_google_calendar_event(id_calendar)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "appointment_form",
            partial: "appointments/form",
            locals: { appointment: @appointment }
          ), status: :unprocessable_entity
        end
        format.html do
          flash.now[:alert] = "Error saving appointment. Please try again."
          render :new, status: :unprocessable_entity
        end
      end
    end
  end


private

  def appointment_params
    params.require(:appointment).permit(
      :package_id,
      :doctor_id,
      :start_date,
      :name,
      :age,
      :phone
    )
  end

  def set_appointment
    @appointment = Appointment.find_by(id: params[:id])
    unless @appointment
      redirect_to admin_appointments_path, alert: "Appointment not found."
    end
  end

  def appointment_params
      params.require(:appointment).permit(:name, :age, :email, :phone, :sex, :doctor_id,
      :package_id, :status, :duration, :start_date, :google_calendar_id)
  end

    def create_google_calendar_event(appointment, package, doctor, doctor_id)
    # Initialize Google Calendar API client
    calendar = Google::Apis::CalendarV3::CalendarService.new
    credentials = google_credentials # Ensure this returns the full client object

    # Set the full credentials object for authorization
    calendar.authorization = credentials


    # Prepare event details
    event = Google::Apis::CalendarV3::Event.new(
      summary: "🖥️ #{package.name} con #{doctor}",
      description: "Nombre: #{appointment.name} \n Telefono: #{appointment.phone}",
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: (appointment.start_date).iso8601,
        time_zone: "America/Mexico_City"
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: appointment.end_date.iso8601,
        time_zone: "America/Mexico_City"
      ),
      color_id: doctor_id
    )

    # Attempt to insert the event
    begin
      created_event = calendar.insert_event("primary", event)
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

  def generate_pdf(appointment)
    Prawn::Document.new do |pdf|
      # Add title
      pdf.text "Detalles de la Cita", size: 24, style: :bold, align: :center
      pdf.move_down 20

      # Add appointment details
      pdf.text "Nombre: #{@appointment.name || 'N/A'}", size: 12
      pdf.text "Doctor: #{@appointment.doctor&.name || 'N/A'}", size: 12
      pdf.text "Paquete: #{@appointment.package&.name || 'N/A'}", size: 12
      pdf.text "Fecha de la Cita: #{I18n.l(@appointment.start_date.in_time_zone('America/Mexico_City'), format: :custom, locale: :es) rescue 'N/A'}", size: 12
      pdf.text "Estado: #{@appointment.status || 'N/A'}", size: 12
      pdf.text "Teléfono: #{@appointment.phone || 'N/A'}", size: 12
      pdf.text "Codigo Unico: #{@appointment.unique_code || 'N/A'}", size: 12
      pdf.text "El codigo unico puede utilizarse para cancelar su cita, porfavor cancelar al menos 24 horas antes de su cita"

      pdf.move_down 20
      pdf.text "Generado el #{I18n.l(Time.zone.now, format: :custom, locale: :es)}", size: 10, align: :right
    end.render
  end
end
