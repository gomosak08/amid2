# frozen_string_literal: true

# app/services/user/appointments/update.rb
module User::Appointments
    class Update
      Result = Struct.new(:success?, :error, keyword_init: true)

      ALLOWED_STATUSES = %w[completed canceled_by_admin].freeze

      def self.call(appointment:, status:, by: :admin)
        unless status.present? && ALLOWED_STATUSES.include?(status)
          return Result.new(success?: false, error: "Estado inválido.")
        end

        ActiveRecord::Base.transaction do
          if status == "canceled_by_admin" && appointment.google_calendar_id.present?
            # Mueve tu lógica de Google aquí o llama a un servicio dedicado:
            # GoogleCalendar::EliminateEvent.call(google_event_id: appointment.google_calendar_id)
            appointment.google_calendar_id = nil
            appointment.canceled_at = Time.current
          end

          appointment.update!(status: status)
        end

        Result.new(success?: true)
      rescue => e
        Result.new(success?: false, error: e.message)
      end
    end
end
