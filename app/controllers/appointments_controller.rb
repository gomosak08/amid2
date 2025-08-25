class AppointmentsController < ApplicationController
  before_action :set_appointment, only: %i[show edit destroy]

  def new
    @ctx = Forms::AppointmentFormContext.call(params: params, appointment: Appointment.new)
  end


  def create
    @package = Package.find_by(id: params.dig(:appointment, :package_id))
    return Responders::Flash422.call(controller: self, msg: "The selected package could not be found.") unless @package

    ok = verify_recaptcha(response: params[:recaptcha_token],
                          action: "appointment_create",
                          minimum_score: 0.0,
                          remote_ip: request.remote_ip)
    return Responders::Flash422.call(controller: self, msg: "No pudimos validar el reCAPTCHA. Intenta de nuevo.",
                                    appointment_params: appointment_params) unless ok

    result = Appointments::Create.call(params: appointment_params, package: @package, caller_role: :user)

    if result.success?
      redirect_to appointment_path(result.appointment),
                  notice: "La cita se creó correctamente.",
                  status: :see_other
    else
      # Si quieres PRG (recomendado), redirige:
      redirect_to new_appointment_path(
                    package_id:       @package.id,
                    doctor_id:        appointment_params[:doctor_id],
                    appointment_date: result.start_date&.to_date
                  ),
                  alert: (result.error || "No se pudo crear la cita. Revisa los errores."),
                  status: :see_other

      # O si prefieres render 422 en la misma petición:
      # Responders::Flash422.call(controller: self, msg: (result.error || "No se pudo crear la cita."),
      #                           appointment_params: appointment_params)
    end
  end


  def show
    respond_to do |format|
      format.html
      format.turbo_stream { render partial: "appointments/show", locals: { appointment: @appointment } }
      format.pdf do
        logo = Rails.root.join("public/logo.png")
        pdf  = Pdf::AppointmentPdf.new(@appointment, logo_path: logo).render
        send_data pdf, filename: "cita_#{@appointment.token}.pdf",
                       type: "application/pdf",
                       disposition: "attachment"
      end
    end
  end

  def edit; end

  def destroy
    Appointments::Cancel.call(appointment: @appointment, by: :client)
    redirect_to root_path, notice: "Cita cancelada correctamente."
  end

  private

  def appointment_params
    params.require(:appointment).permit(:name, :age, :email, :phone, :sex, :doctor_id, :package_id, :duration, :start_date)
  end

  def set_appointment
    @appointment = Appointment.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to new_appointment_path, alert: "Appointment not found."
  end
end
