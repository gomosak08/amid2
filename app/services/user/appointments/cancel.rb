# app/services/user/appointments/cancel.rb
module User::Appointments
  class Cancel
    def self.call(appointment:, by:)
      if appointment.google_calendar_id.present?
        begin
          User::GoogleCalendar::Events::Delete.call(event_id: appointment.google_calendar_id)
        rescue => e
          Rails.logger.warn("GCal delete failed appt=#{appointment.id}: #{e.class} - #{e.message}")
        end
      end

      status = by.to_s == "client" ? :canceled_by_client : :canceled_by_admin
      appointment.update!(status: status, canceled_at: Time.current, google_calendar_id: nil)
      appointment
    end
  end
end
