module Api
  module Internal
    module V1
      class DoctorCalendarController < BaseController
        MAX_PERIOD_DAYS = 90

        def show
          doctor = Doctor.find(params[:doctor_id])
          date_from, date_to = requested_period
          timezone = params[:timezone].presence || "America/Mexico_City"

          appointments = Appointment
            .includes(:doctor, :package)
            .where(doctor_id: doctor.id)
            .where("start_date < ? AND end_date > ?", date_to.end_of_day, date_from.beginning_of_day)
          appointments = appointments.where(dummy: [false, nil]) if Appointment.column_names.include?("dummy")

          blocks = DoctorCalendarBlock.active
            .where(doctor_id: doctor.id)
            .overlapping(date_from.beginning_of_day, date_to.end_of_day)

          legacy_events = Api::Internal::V1::LegacyCalendarBlockReader.new(
            doctor: doctor,
            date_from: date_from,
            date_to: date_to,
            timezone: timezone
          ).call

          events = appointments.map { |appointment| serialize_calendar_appointment(appointment) } +
            blocks.map { |block| serialize_calendar_block(block) } +
            legacy_events

          event_types = params[:event_types].to_s.split(",").map(&:strip).reject(&:blank?)
          events.select! { |event| event_types.include?(event[:resource_type]) } if event_types.present?
          events.sort_by! { |event| event[:start_at].to_time }

          render_success(
            data: events,
            meta: {
              doctor_id: doctor.id,
              timezone: timezone,
              date_from: date_from.iso8601,
              date_to: date_to.iso8601
            }
          )
        end

        private

        def requested_period
          date_from = parse_iso8601_date(
            params[:date_from].presence || Date.current.iso8601,
            parameter: "date_from"
          )
          date_to = parse_iso8601_date(
            params[:date_to].presence || (date_from + 30.days).iso8601,
            parameter: "date_to"
          )

          raise ArgumentError, "La fecha final no puede ser anterior a la inicial." if date_to < date_from
          if (date_to - date_from).to_i > MAX_PERIOD_DAYS
            raise ArgumentError, "El periodo máximo permitido es de #{MAX_PERIOD_DAYS} días."
          end

          [date_from, date_to]
        end
      end
    end
  end
end