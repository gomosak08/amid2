# app/services/appointments/cancel.rb
# frozen_string_literal: true

module Appointments
  class Cancel
    def self.call(appointment:, by:)
      GoogleCalendar::Events::Delete.call(event_id: appointment.google_calendar_id)
        appointment.update(status: "canceled_by_client", canceled_at: Time.current)

      appointment
    end
  end
end
