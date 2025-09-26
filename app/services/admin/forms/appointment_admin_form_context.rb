# frozen_string_literal: true

module Admin
  module Forms
    class AppointmentAdminFormContext
      # params: ActionController::Parameters
      # appointment: Appointment (normalmente Appointment.new)
      def self.call(params:, appointment:)
        new(params:, appointment:).call
      end

      def initialize(params:, appointment:)
        @params      = params
        @appointment = appointment
      end

      def call
        {
          appointment: @appointment,
          packages:    packages,
          package:     package,
          doctor_id:   doctor_id,
          start_date:  start_date,
          duration:    duration
        }
      end

      private

      attr_reader :params

      def packages
        Package.order(:name)
      end

      def package
        pid = params[:package_id].presence || params.dig(:appointment, :package_id).presence
        return nil unless pid
        Package.find_by(id: pid)
      end

      def doctor_id
        params[:doctor_id].presence || params.dig(:appointment, :doctor_id).presence
      end

      def start_date
        raw = params[:appointment_date].presence || params.dig(:appointment, :start_date).presence
        return nil unless raw
        if raw.respond_to?(:to_date)
          raw.to_date
        else
          Time.zone.parse(raw)&.to_date rescue nil
        end
      end

      def duration
        # Preferimos duración del paquete; si no, 30 min por defecto
        package&.duration.presence || params[:duration].presence || 30
      end
    end
  end
end
