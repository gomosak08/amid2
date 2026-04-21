# frozen_string_literal: true

class Admin::AppointmentsController < ApplicationController
  include User::Concerns::AvailableFields

  before_action :authenticate_user!
  before_action :require_admin_or_assistant_or_doctor
  before_action :set_appointment, only: [ :show, :edit, :update, :destroy, :cancel, :attach_results, :remove_result ]
  before_action :require_results_permission, only: [ :attach_results, :remove_result ]

  def new
    @ctx      = Admin::Forms::AppointmentAdminFormContext.call(params: params, appointment: Appointment.new)
    @packages = @ctx[:packages]
  end

  def index
    @doctors = Doctor.order(:name)

    scope = Appointment
              .includes(:doctor, :package)
              .order(start_date: :desc)

    # Restricción de permisos para médicos
    if current_user&.doctor?
      if current_user.doctor.present?
        scope = scope.where(doctor_id: current_user.doctor.id)
      else
        scope = scope.none
      end
    end

    # Fecha (filtra por el día completo en CDMX)
    if params[:date].present?
      begin
        d  = Date.parse(params[:date])
        tz = ActiveSupport::TimeZone["America/Mexico_City"]

        from = tz.local(d.year, d.month, d.day).beginning_of_day
        to   = tz.local(d.year, d.month, d.day).end_of_day

        scope = scope.where(start_date: from..to)
      rescue ArgumentError
        # fecha inválida: se ignora
      end
    end

    # Doctores múltiples
    # Soporta la nueva forma: doctor_ids[]
    # Y mantiene compatibilidad con la vieja: doctor_id
    doctor_ids = Array(params[:doctor_ids]).reject(&:blank?)
    doctor_ids << params[:doctor_id] if params[:doctor_id].present?
    doctor_ids = doctor_ids.flatten.reject(&:blank?).uniq

    if doctor_ids.any?
      scope = scope.where(doctor_id: doctor_ids)
    end

    # Estados múltiples
    # Soporta la nueva forma: statuses[]
    # Y mantiene compatibilidad con la vieja: status
    statuses = Array(params[:statuses]).reject(&:blank?)
    statuses << params[:status] if params[:status].present?
    statuses = statuses.flatten.reject(&:blank?).uniq

    if statuses.any?
      if Appointment.respond_to?(:statuses)
        valid_statuses = statuses.select { |s| Appointment.statuses.key?(s) }

        if valid_statuses.any?
          scope = scope.where(status: valid_statuses)
        end
      else
        scope = scope.where(status: statuses)
      end
    end

    @appointments = scope
  end

  def cancel
    id = @appointment.google_calendar_id
    User::GoogleCalendar::Events::Delete.call(event_id: id) if id.present?

    if @appointment.update(status: "canceled_by_admin", canceled_at: Time.current)
      flash[:notice] = "Appointment successfully canceled."
      redirect_to admin_appointments_path
    else
      flash[:alert] = "Failed to cancel the appointment. Please try again."
      redirect_to admin_appointments_path
    end
  end

  def create
    @package = Package.find_by(id: params.dig(:appointment, :package_id))
    return Responders::Flash422.call(controller: self, msg: "No encontramos el paquete seleccionado.") unless @package

    result = Admin::Appointments::Create.call(
      params: appointment_params,
      package: @package,
      caller_role: (current_user&.role || :admin),
      caller_user: current_user
    )

    respond_to do |format|
      if result.success?
        format.turbo_stream do
          redirect_to admin_appointment_path(result.appointment, download: 1, format: :html),
                      status: :see_other,
                      notice: "La cita se creó correctamente."
        end

        format.html do
          redirect_to admin_appointment_path(result.appointment, download: 1, format: :html),
                      status: :see_other,
                      notice: "La cita se creó correctamente."
        end
      else
        msg = (result.error || "No se pudo crear la cita. Revisa los errores.")

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "flash",
            partial: "shared/flash",
            locals: { alert: msg }
          ), status: :unprocessable_entity
        end

        format.html do
          redirect_to new_admin_appointment_path(
                        package_id: @package.id,
                        doctor_id: appointment_params[:doctor_id],
                        appointment_date: result.start_date&.to_date
                      ),
                      alert: msg,
                      status: :see_other
        end
      end
    end
  end

  def show
    # Si viene con ?download=1, la vista disparará la descarga y limpiará la URL
    @download_once = params[:download].present?
    @pdf_url = admin_appointment_path(@appointment, format: :pdf) if @download_once

    respond_to do |format|
      format.html
      format.pdf do
        logo_path = Rails.root.join("public/logo.png")
        pdf = User::Pdf::AppointmentPdf.new(@appointment, logo_path: logo_path).render

        send_data pdf,
                  filename: "cita_#{@appointment.unique_code || @appointment.id}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end

  def attach_results
    if params[:study_results].present?
      @appointment.study_results.attach(params[:study_results])
      flash[:notice] = "Resultados adjuntados exitosamente."
    else
      flash[:alert] = "Debes seleccionar al menos un archivo."
    end
    redirect_to admin_appointment_path(@appointment)
  end

  def remove_result
    begin
      attachment = @appointment.study_results.find(params[:attachment_id])
      attachment.purge
      flash[:notice] = "El archivo ha sido eliminado."
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Archivo no encontrado."
    end
    redirect_to admin_appointment_path(@appointment)
  end

  def edit
  end

  def update
    permitted = params.require(:appointment).permit(:status)

    result = User::Appointments::Update.call(
      appointment: @appointment,
      status: permitted[:status],
      by: (current_user&.role || :admin)
    )

    if result.success?
      respond_to do |format|
        format.html do
          redirect_to [ :admin, @appointment ],
                      notice: "Estado actualizado.",
                      status: :see_other
        end

        format.turbo_stream do
          redirect_to [ :admin, @appointment ],
                      status: :see_other,
                      flash: { notice: "Estado actualizado." }
        end
      end
    else
      flash.now[:alert] = result.error || "No se pudo actualizar la cita."

      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    Appointments::Cancel.call(appointment: @appointment, by: (current_user&.role || :admin))
    redirect_to admin_appointments_path, notice: "Cita cancelada correctamente.", status: :see_other
  end

  private

  def appointment_params
    params.require(:appointment).permit(
      :name, :age, :email, :phone, :sex, :doctor_id, :package_id, :duration, :start_date
    )
  end

  def set_appointment
    @appointment = Appointment.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to new_admin_appointment_path, alert: "Appointment not found."
  end

  def require_admin_or_assistant_or_doctor
    unless current_user&.admin? || current_user&.assistant? || current_user&.doctor?
      redirect_to root_path, alert: "No tienes permiso para acceder a esta sección."
    end
  end

  def require_results_permission
    unless current_user&.can_manage_results?
      redirect_to admin_appointment_path(@appointment), alert: "No tienes permiso para gestionar resultados médicos."
    end
  end
end
