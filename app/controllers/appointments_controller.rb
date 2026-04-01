class AppointmentsController < ApplicationController
  before_action :set_appointment, only: %i[show edit update destroy]

  def new
    @package = Package.find_by(id: params[:package_id] || params.dig(:appointment, :package_id))

    if @package.blank?
      @packages = Package.order(:kind, :name)
      render :select_package
      return
    end

    @ctx = User::Forms::AppointmentFormContext.call(
      params: params,
      appointment: Appointment.new(package: @package)
    )

    if params.dig(:appointment, :doctor_id).present? &&
      params[:appointment_date].present? &&
      @ctx.available_times.blank?
      flash.now[:alert] = "No hay disponibilidad para el doctor seleccionado en la fecha elegida."
    end
  end

  def create
    @package = Package.find_by(id: params.dig(:appointment, :package_id))
    return Responders::Flash422.call(controller: self, msg: "No se encontró el paquete seleccionado.") unless @package

    phone_e164 = PhoneNormalizer.to_e164(appointment_params[:phone])
    phone_ban  = PhoneBan.active_now.find_by(phone_e164: phone_e164)

    if phone_ban.present?
      msg =
        if phone_ban.hard?
          "Este número no puede agendar ni contactar a un asistente."
        else
          "Este número no puede agendar en línea. Debe hacerlo con un asistente."
        end

      return Responders::Flash422.call(
        controller: self,
        msg: msg,
        appointment_params: appointment_params
      )
    end

    ok = verify_recaptcha(
      response: params[:recaptcha_token],
      action: "appointment_create",
      minimum_score: 0.0,
      remote_ip: request.remote_ip
    )

    return Responders::Flash422.call(
      controller: self,
      msg: "No pudimos validar el reCAPTCHA. Intenta de nuevo.",
      appointment_params: appointment_params
    ) unless ok

    result = User::Appointments::Create.call(
      params: appointment_params,
      package: @package,
      caller_role: :user
    )

    if result.success?
      redirect_to appointment_path(result.appointment),
                  notice: "La cita se creó correctamente.",
                  status: :see_other
    else
      redirect_to new_appointment_path(
                    package_id: @package.id,
                    appointment: {
                      doctor_id: appointment_params[:doctor_id],
                      package_id: @package.id
                    },
                    appointment_date: result.start_date&.to_date
                  ),
                  alert: (result.error || "No se pudo crear la cita. Revisa los errores."),
                  status: :see_other
    end
  end

  def show
    respond_to do |format|
      format.html
      format.turbo_stream { render partial: "appointments/show", locals: { appointment: @appointment } }
      format.pdf do
        logo = Rails.root.join("public/logo.png")
        pdf  = User::Pdf::AppointmentPdf.new(@appointment, logo_path: logo).render

        send_data pdf,
                  filename: "cita_#{@appointment.token}.pdf",
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end

  def edit
  end

  def update
    # aquí pones tu lógica de actualización si ya la tienes
  end

  def destroy
    User::Appointments::Cancel.call(appointment: @appointment, by: :client)
    redirect_to root_path, notice: "Cita cancelada correctamente."
  end

  def find
  end

  def locate
    code = params[:unique_code].to_s.strip.upcase
    @appointment = Appointment.includes(:doctor, :package).find_by(unique_code: code)

    if @appointment.present?
      redirect_to edit_appointment_path(@appointment),
                  notice: "Cita encontrada. Puedes editarla.",
                  status: :see_other
    else
      flash.now[:alert] = "Código inválido o cita no encontrada."
      render :find, status: :not_found
    end
  end

  private

  def appointment_params
    params.require(:appointment).permit(
      :name,
      :age,
      :email,
      :phone,
      :sex,
      :doctor_id,
      :package_id,
      :duration,
      :start_date
    )
  end

  def set_appointment
    @appointment = Appointment.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to find_appointments_path, alert: "Cita no encontrada."
  end
end
