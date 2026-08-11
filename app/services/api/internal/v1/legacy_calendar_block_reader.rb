module Api
  module Internal
    module V1
      class LegacyCalendarBlockReader
        MODEL_NAMES = %w[DoctorUnavailability DoctorTimeBlock].freeze

        attr_reader :doctor, :date_from, :date_to, :timezone

        def initialize(doctor:, date_from:, date_to:, timezone:)
          @doctor = doctor
          @date_from = date_from
          @date_to = date_to
          @timezone = ActiveSupport::TimeZone[timezone] || Time.zone
        end

        def call
          MODEL_NAMES.flat_map do |model_name|
            next [] unless Object.const_defined?(model_name)

            records_for(Object.const_get(model_name)).flat_map do |record|
              events_for(record, model_name)
            end
          end
        rescue StandardError => error
          Rails.logger.warn(
            "[Internal API calendar] Legacy blocks could not be read: " \
            "#{error.class}: #{error.message}"
          )
          []
        end

        private

        def records_for(model)
          return [] unless model.respond_to?(:column_names)
          return [] unless model.column_names.include?("doctor_id")

          scope = model.where(doctor_id: doctor.id)
          scope = scope.where(active: true) if model.column_names.include?("active")
          scope = scope.where(canceled_at: nil) if model.column_names.include?("canceled_at")
          scope.to_a
        end

        def events_for(record, model_name)
          if recurring_record?(record)
            recurring_events(record, model_name)
          else
            event = one_off_event(record, model_name)
            event ? [event] : []
          end
        end

        def one_off_event(record, model_name)
          starts_at, ends_at, all_day = interval_for(record)
          return nil unless starts_at && ends_at
          return nil unless starts_at < date_to.end_of_day && ends_at > date_from.beginning_of_day

          event_hash(record, model_name, starts_at, ends_at, all_day)
        end

        def recurring_events(record, model_name)
          day = normalized_weekday(attribute(record, :day_of_week))
          return [] if day.nil?

          (date_from..date_to).filter_map do |date|
            next unless date.wday == day

            start_clock = clock(attribute(record, :start_time)) || "00:00"
            end_clock = clock(attribute(record, :end_time)) || "23:59"
            starts_at = local_time(date, start_clock)
            ends_at = local_time(date, end_clock)
            event_hash(record, model_name, starts_at, ends_at, false)
          end
        end

        def interval_for(record)
          starts_at = first_attribute(record, :starts_at, :start_at, :start_date)
          ends_at = first_attribute(record, :ends_at, :end_at, :end_date)
          date = first_attribute(record, :date, :unavailable_date)

          if starts_at.respond_to?(:hour) && ends_at.respond_to?(:hour)
            return [starts_at.in_time_zone(timezone), ends_at.in_time_zone(timezone), all_day?(record)]
          end

          if starts_at.respond_to?(:to_date) && ends_at.respond_to?(:to_date)
            start_date = starts_at.to_date
            end_date = ends_at.to_date
            start_clock = clock(attribute(record, :start_time))
            end_clock = clock(attribute(record, :end_time))

            if start_clock && end_clock
              return [local_time(start_date, start_clock), local_time(end_date, end_clock), false]
            end

            return [
              timezone.local(start_date.year, start_date.month, start_date.day),
              timezone.local(end_date.year, end_date.month, end_date.day).end_of_day,
              true
            ]
          end

          if date.respond_to?(:to_date)
            date = date.to_date
            start_clock = clock(attribute(record, :start_time)) || "00:00"
            end_clock = clock(attribute(record, :end_time)) || "23:59"
            return [local_time(date, start_clock), local_time(date, end_clock), all_day?(record)]
          end

          [nil, nil, false]
        end

        def event_hash(record, model_name, starts_at, ends_at, all_day)
          reason = first_attribute(record, :reason, :notes, :description).presence

          {
            id: "legacy-#{model_name.underscore}-#{record.id}-#{starts_at.to_i}",
            resource_type: "legacy_time_block",
            resource_id: record.id,
            title: reason || "No disponible",
            start_at: starts_at,
            end_at: ends_at,
            all_day: all_day,
            status: "active",
            editable: false,
            metadata: {
              reason: reason,
              model: model_name
            }
          }
        end

        def recurring_record?(record)
          record.respond_to?(:day_of_week) && attribute(record, :day_of_week).present?
        end

        def all_day?(record)
          record.respond_to?(:all_day) ? !!record.all_day : false
        end

        def local_time(date, value)
          hour, minute = value.split(":").map(&:to_i)
          timezone.local(date.year, date.month, date.day, hour, minute)
        end

        def clock(value)
          return nil if value.blank?
          return value.strftime("%H:%M") if value.respond_to?(:strftime)

          match = value.to_s.match(/(\d{1,2}):(\d{2})/)
          match ? format("%02d:%02d", match[1].to_i, match[2].to_i) : nil
        end

        def normalized_weekday(value)
          return value if value.is_a?(Integer) && value.between?(0, 6)

          mapping = {
            "sunday" => 0, "domingo" => 0,
            "monday" => 1, "lunes" => 1,
            "tuesday" => 2, "martes" => 2,
            "wednesday" => 3, "miercoles" => 3, "miércoles" => 3,
            "thursday" => 4, "jueves" => 4,
            "friday" => 5, "viernes" => 5,
            "saturday" => 6, "sabado" => 6, "sábado" => 6
          }
          mapping[value.to_s.downcase] || Integer(value, exception: false)
        end

        def first_attribute(record, *names)
          names.each do |name|
            value = attribute(record, name)
            return value if value.present?
          end
          nil
        end

        def attribute(record, name)
          return nil unless record.respond_to?(name)

          record.public_send(name)
        end
      end
    end
  end
end