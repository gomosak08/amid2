class AppointmentMailer < ApplicationMailer
    default from: 'no-reply@yourapp.com'

    def appointment_confirmation(appointment)
      @appointment = appointment
      mail(
        to: @appointment.email,
        subject: 'Appointment Confirmation'
      )
    end
end
