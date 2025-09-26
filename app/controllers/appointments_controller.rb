class AppointmentsController < ApplicationController
  before_action :set_appointment, only: %i[show edit destroy]

  def new
    @ctx = User::Forms::AppointmentFormContext.call(params: params, appointment: Appointment.new)
  end


  def create
    @package = Package.find_by(id: params.dig(:appointment, :package_id))
    return Responders::Flash422.call(controller: self, msg: "No se encontro el paquete seleccionado.") unless @package

    ok = verify_recaptcha(response: params[:recaptcha_token],
                          action: "appointment_create",
                          minimum_score: 0.0,
                          remote_ip: request.remote_ip)
    return Responders::Flash422.call(controller: self, msg: "No pudimos validar el reCAPTCHA. Intenta de nuevo.",
                                    appointment_params: appointment_params) unless ok

    result = User::Appointments::Create.call(params: appointment_params, package: @package, caller_role: :user)

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
        pdf  = User::Pdf::AppointmentPdf.new(@appointment, logo_path: logo).render
        send_data pdf, filename: "cita_#{@appointment.token}.pdf",
                       type: "application/pdf",
                       disposition: "attachment"
      end
    end
  end

  def edit; end

  def destroy
    User::Appointments::Cancel.call(appointment: @appointment, by: :client)
    redirect_to root_path, notice: "Cita cancelada correctamente."
  end

  def locate
    code = params[:unique_code].to_s.strip.upcase
    @appointment = Appointment.includes(:doctor, :package).find_by(unique_code: code)

    respond_to do |format|
      if @appointment
        # ✅ Éxito: manda al formulario de edición
        format.turbo_stream { redirect_to edit_appointment_path(@appointment), status: :see_other, notice: "Cita encontrada. Puedes editarla." }
        format.html         { redirect_to edit_appointment_path(@appointment),                         notice: "Cita encontrada. Puedes editarla." }
      else
        msg = "Código inválido o cita no encontrada."

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
              "flash",
              partial: "appointments/flash",
              locals: { alert: msg }
            )
          ], status: :not_found
        end

        format.html do
          flash.now[:alert] = msg
          render :find, status: :not_found  # o :index, según tu template de búsqueda
        end
      end
    end
  end


  private

  def appointment_params
    params.require(:appointment).permit(:name, :age, :email, :phone, :sex, :doctor_id, :package_id, :duration, :start_date)
  end

  def set_appointment
    @appointment = Appointment.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    redirect_to new_appointment_path, alert: "Cita no encontrada."
  end
end
