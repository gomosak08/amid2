module Api
  module Internal
    module V1
      class AppointmentWriter
        attr_reader :appointment, :payload, :idempotency_key, :request_digest

        def initialize(appointment: nil, payload:, idempotency_key: nil, request_digest: nil)
          @appointment = appointment || Appointment.new
          @payload = payload.respond_to?(:to_unsafe_h) ? payload.to_unsafe_h : payload.to_h
          @payload = @payload.deep_stringify_keys
          @idempotency_key = idempotency_key
          @request_digest = request_digest
        end

        def build
          doctor = Doctor.find(payload.fetch("doctor_id"))
          package = Package.find(payload.fetch("package_id"))
          start_at = parse_time(payload.fetch("start_at"))

          assign_schedule(doctor: doctor, package: package, start_at: start_at)
          assign_patient(payload.fetch("patient").deep_stringify_keys)
          assign_optional_attributes
          assign_creation_defaults
          appointment
        end

        def assign_updates
          doctor = payload["doctor_id"].present? ? Doctor.find(payload["doctor_id"]) : appointment.doctor
          package = payload["package_id"].present? ? Package.find(payload["package_id"]) : appointment.package
          start_at = payload["start_at"].present? ? parse_time(payload["start_at"]) : appointment.start_date

          assign_schedule(doctor: doctor, package: package, start_at: start_at)
          assign_patient(payload["patient"].deep_stringify_keys) if payload["patient"].present?
          assign_optional_attributes
          appointment
        end

        private

        def assign_schedule(doctor:, package:, start_at:)
          duration = package.duration.to_i
          raise ArgumentError, "El paquete no tiene una duración válida." if duration <= 0

          appointment.doctor = doctor
          appointment.package = package
          assign_if_column(:start_date, start_at)
          assign_if_column(:end_date, start_at + duration.minutes)
          assign_if_column(:duration, duration)
        end

        def assign_patient(patient)
          name = patient["name"].to_s.strip
          raise ArgumentError, "El nombre del paciente es obligatorio." if name.blank?

          assign_if_column(:name, name)
          assign_if_column(:age, Integer(patient["age"], exception: false))
          assign_if_column(:phone, patient["phone"].to_s.strip)
          assign_if_column(:email, patient["email"].to_s.strip.presence)
          assign_if_column(:sex, patient["sex"].presence)
          assign_if_column(:external_patient_id, patient["external_patient_id"].presence)
        end

        def assign_optional_attributes
          assign_if_column(:notes, payload["notes"]) if payload.key?("notes")
          assign_if_column(:source, payload["source"].presence || "clinical_history")
          assign_if_column(:clinic_id, payload["clinic_id"]) if payload["clinic_id"].present?
        end

        def assign_creation_defaults
          assign_if_column(:dummy, false)
          assign_if_column(:status, default_enum_value("status", "scheduled"))
          assign_if_column(
            :scheduled_by,
            default_enum_value("scheduled_by", "admin", "doctor", "patient")
          )
          assign_if_column(:api_idempotency_key, idempotency_key)
          assign_if_column(:api_request_digest, request_digest)
        end

        def default_enum_value(enum_name, *preferred)
          enum = Appointment.defined_enums[enum_name].to_h
          return preferred.first if enum.blank?

          preferred.find { |value| enum.key?(value) } || enum.keys.first
        end

        def assign_if_column(name, value)
          return unless Appointment.column_names.include?(name.to_s)
          return if value.nil? && %i[age sex email].include?(name)

          appointment.public_send("#{name}=", value)
        end

        def parse_time(value)
          Time.iso8601(value.to_s)
        rescue ArgumentError
          raise ArgumentError,
                "start_at debe usar formato ISO 8601, por ejemplo " \
                "2026-07-25T10:00:00-06:00."
        end
      end
    end
  end
end