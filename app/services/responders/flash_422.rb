# app/services/responders/flash_422.rb
module Responders
  class Flash422
    def self.call(controller:, msg:, appointment_params: nil)
      # Construye el contexto del formulario (si usas @ctx en la vista)
      ctx = Forms::AppointmentFormContext.call(
        params: controller.params,
        appointment: appointment_params ? Appointment.new(appointment_params) : Appointment.new
      )
      controller.instance_variable_set(:@ctx, ctx)

      controller.respond_to do |format|
        format.turbo_stream do
          flash_html = controller.render_to_string(
            partial: "shared/flash",
            formats: [ :html ],                    # <- fuerza HTML
            locals:  { alert: msg }
          )
          stream = controller.view_context.turbo_stream.update("flash", flash_html)
          controller.render turbo_stream: stream, status: :unprocessable_entity
        end

        format.html do
          controller.flash.now[:alert] = msg
          controller.render :new, status: :unprocessable_entity
        end
      end
      nil
    end
  end
end
