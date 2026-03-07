# frozen_string_literal: true

module Responders
  class Flash422
    def self.call(controller:, msg:, appointment_params: nil)
      controller.flash.now[:alert] = msg

      appointment =
        if appointment_params.present?
          Appointment.new(appointment_params)
        else
          Appointment.new
        end

      controller.instance_variable_set(:@appointment, appointment)

      ctx = User::Forms::AppointmentFormContext.call(
        params: ActionController::Parameters.new(
          appointment: appointment_params || {}
        ),
        appointment: appointment
      )

      controller.instance_variable_set(:@ctx, ctx)

      controller.render :new, status: :unprocessable_entity
    end
  end
end
