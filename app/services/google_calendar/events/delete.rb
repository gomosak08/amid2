# frozen_string_literal: true

module GoogleCalendar
  module Events
    class Delete
      # Devuelve true si se considera borrado (o no había id), false si falla.
      def self.call(event_id:, calendar_id: "primary")
        return true if event_id.blank?

        service = GoogleCalendar::Client.build
        service.delete_event(calendar_id, event_id)
        true
      rescue Google::Apis::ClientError => e
        # Si no existe el evento (404), lo consideramos ya borrado
        if e.respond_to?(:status_code) && e.status_code.to_i == 404
          true
        else
          Rails.logger.error("[GoogleCalendar::Events::Delete] #{e.class}: #{e.message}")
          false
        end
      rescue => e
        Rails.logger.error("[GoogleCalendar::Events::Delete] #{e.class}: #{e.message}")
        false
      end
    end
  end
end
