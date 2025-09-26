# frozen_string_literal: true

class Admin::AppointmentsController < ApplicationController
  include User::Concerns::AvailableFields

  before_action :authenticate_user!
  before_action :require_admin_or_secretary
  before_action :set_appointment, only: [ :show, :edit, :update, :destroy, :cancel ]

  def new
    @ctx      = Admin::Forms::AppointmentAdminFormContext.call(params: params, appointment: Appointment.new)
    @packages = @ctx[:packages]
  end

  def index
    @doctors = Doctor.order(:name)

    scope = Appointment.order(start_date: :desc).includes(:doctor, :package)

    # Fecha (filtra por el día completo en CDMX)
    if params[:date].present?
      begin
        d  = Date.parse(params[:date])
        tz = ActiveSupport::TimeZone["America/Mexico_City"]
        from = tz.local(d.year, d.month, d.day).beginning_of_day
        to   = tz.local(d.year, d.month, d.day).end_of_day
        scope = scope.where(start_date: from..to)
      rescue ArgumentError
        # fecha inválida -> ignora o puedes poner un flash si quieres
      end
    end

    # Doctor
    if params[:doctor_id].present?
      scope = scope.where(doctor_id: params[:doctor_id])
    end

    # Estado (soporta enum)
    if params[:status].present?
      if Appointment.respond_to?(:statuses) && Appointment.statuses.key?(params[:status])
        scope = scope.where(status: Appointment.statuses[params[:status]])
      else
        scope = scope.where(status: params[:status])  # por si status es string simple
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
    caller_role: (current_user&.role || :admin)
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
                      package_id:       @package.id,
                      doctor_id:        appointment_params[:doctor_id],
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
        format.html { redirect_to [ :admin, @appointment ], notice: "Estado actualizado.", status: :see_other }
        format.turbo_stream do
          redirect_to [ :admin, @appointment ], status: :see_other, flash: { notice: "Estado actualizado." }
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

  def require_admin_or_secretary
    unless current_user&.admin? || current_user&.secretary?
      redirect_to root_path, alert: "No tienes permiso para acceder a esta sección."
    end
  end
end
