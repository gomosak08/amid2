# frozen_string_literal: true

module GoogleCalendar
  module Events
    class Create
      # Devuelve el event_id (String) o nil si falla.
      # color_id válido: "1".."11" (opcional). Si no lo pasas, se calcula con el doctor_id.
      def self.call(appointment:, package:, doctor_name:, calendar_id: "primary",
                          timezone: "America/Mexico_City", color_id: nil, caller_role: :user, emoji: nil)
        service = GoogleCalendar::Client.build

        start_time = appointment.start_date
        end_time   = appointment.end_date
        raise "Appointment must have start/end" if start_time.blank? || end_time.blank?

        # Color determinístico por doctor_id si no se define
        color_id ||= ((appointment.doctor_id.to_i % 11) + 1).to_s

        emoji ||= case caller_role.to_s
        when "admin" then "💻"
        when "user"  then "👤"
        else "🗓"
        end

        title = "#{emoji} #{package&.name || 'Consulta'} con #{doctor_name}"

        event = Google::Apis::CalendarV3::Event.new(
          summary: title,
          description: [
            ("Paciente: #{appointment.name}" if appointment.respond_to?(:name)),
            ("Teléfono: #{appointment.phone}" if appointment.respond_to?(:phone) && appointment.phone.present?),
            ("Código: #{appointment.unique_code}" if appointment.respond_to?(:unique_code) && appointment.unique_code.present?)
          ].compact.join("\n"),
          start: Google::Apis::CalendarV3::EventDateTime.new(
            date_time: start_time.iso8601,
            time_zone: timezone
          ),
          end: Google::Apis::CalendarV3::EventDateTime.new(
            date_time: end_time.iso8601,
            time_zone: timezone
          ),
          color_id: color_id
        )

        created = service.insert_event(calendar_id, event)
        created&.id
      rescue Google::Apis::AuthorizationError, Google::Apis::ServerError, Google::Apis::ClientError => e
        Rails.logger.error("[GoogleCalendar::Events::Create] #{e.class}: #{e.message}")
        nil
      rescue => e
        Rails.logger.error("[GoogleCalendar::Events::Create] #{e.class}: #{e.message}")
        nil
      end
    end
  end
end
