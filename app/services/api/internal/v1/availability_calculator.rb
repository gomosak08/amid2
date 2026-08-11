module Api
  module Internal
    module V1
      class AvailabilityCalculator
        DAY_KEYS = {
          0 => %w[sunday domingo dom 0],
          1 => %w[monday lunes lun 1],
          2 => %w[tuesday martes mar 2],
          3 => %w[wednesday miercoles miércoles mie mié 3],
          4 => %w[thursday jueves jue 4],
          5 => %w[friday viernes vie 5],
          6 => %w[saturday sabado sábado sab sáb 6]
        }.freeze

        attr_reader :doctor, :package, :date_from, :date_to, :timezone

        def initialize(doctor:, package:, date_from:, date_to:, timezone:)
          @doctor = doctor
          @package = package
          @date_from = date_from
          @date_to = date_to
          @timezone = ActiveSupport::TimeZone[timezone]
          raise ArgumentError, "La zona horaria no es válida." unless @timezone
        end

        def call
          Time.use_zone(timezone) do
            (date_from..date_to).map do |date|
              {
                date: date.iso8601,
                slots: slots_for(date)
              }
            end
          end
        end

        private

        def slots_for(date)
          duration = package.duration.to_i
          interval = ENV.fetch("APPOINTMENT_SLOT_INTERVAL_MINUTES", duration).to_i
          interval = duration if interval <= 0

          working_periods_for(date).flat_map do |period|
            start_at = zoned_time(date, period.fetch(:start))
            period_end = zoned_time(date, period.fetch(:end))
            slots = []

            while start_at + duration.minutes <= period_end
              end_at = start_at + duration.minutes

              if start_at.future? && slot_available?(start_at, end_at, duration)
                slots << {
                  start_at: start_at.iso8601,
                  end_at: end_at.iso8601
                }
              end

              start_at += interval.minutes
            end

            slots
          end
        end

        def working_periods_for(date)
          hours = doctor.respond_to?(:available_hours) ? doctor.available_hours : nil
          return [] unless hours.is_a?(Hash)

          raw = DAY_KEYS.fetch(date.wday).filter_map do |key|
            hours[key] || hours[key.to_sym]
          end.first

          normalize_periods(raw)
        end

        def normalize_periods(raw)
          return [] if raw.blank? || raw == false

          values = raw.is_a?(Array) ? raw : [raw]

          values.filter_map do |value|
            case value
            when Hash
              value = value.deep_stringify_keys
              next if value["enabled"] == false

              start_value = value["start"] || value["start_time"] || value["from"]
              end_value = value["end"] || value["end_time"] || value["to"]
              next if start_value.blank? || end_value.blank?

              { start: normalize_clock(start_value), end: normalize_clock(end_value) }
            when String
              start_value, end_value = value.split("-", 2).map(&:strip)
              next if start_value.blank? || end_value.blank?

              { start: normalize_clock(start_value), end: normalize_clock(end_value) }
            end
          end
        end

        def normalize_clock(value)
          return value.strftime("%H:%M") if value.respond_to?(:strftime)

          match = value.to_s.match(/\A(\d{1,2}):(\d{2})/)
          raise ArgumentError, "Horario inválido: #{value}." unless match

          format("%02d:%02d", match[1].to_i, match[2].to_i)
        end

        def zoned_time(date, clock)
          hour, minute = clock.split(":").map(&:to_i)
          timezone.local(date.year, date.month, date.day, hour, minute)
        end

        def slot_available?(start_at, end_at, duration)
          return false if DoctorCalendarBlock.active
            .where(doctor_id: doctor.id)
            .where("starts_at < ? AND ends_at > ?", end_at, start_at)
            .exists?

          candidate = Appointment.new
          assign_candidate(candidate, start_at, end_at, duration)
          candidate.valid?
        end

        def assign_candidate(candidate, start_at, end_at, duration)
          candidate.doctor = doctor
          candidate.package = package
          assign_if_column(candidate, :name, "Paciente disponibilidad API")
          assign_if_column(candidate, :age, 30)
          assign_if_column(candidate, :phone, "+525500000000")
          assign_if_column(candidate, :email, "availability@example.invalid")
          assign_if_column(candidate, :start_date, start_at)
          assign_if_column(candidate, :end_date, end_at)
          assign_if_column(candidate, :duration, duration)
          assign_if_column(candidate, :dummy, false)
          assign_if_column(candidate, :status, default_enum_value("status", "scheduled"))
          assign_if_column(
            candidate,
            :scheduled_by,
            default_enum_value("scheduled_by", "admin", "doctor", "patient")
          )
        end

        def assign_if_column(record, name, value)
          return unless Appointment.column_names.include?(name.to_s)

          record.public_send("#{name}=", value)
        end

        def default_enum_value(enum_name, *preferred)
          enum = Appointment.defined_enums[enum_name].to_h
          return preferred.first if enum.blank?

          preferred.find { |value| enum.key?(value) } || enum.keys.first
        end
      end
    end
  end
end