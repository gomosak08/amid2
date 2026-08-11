module Api
  module Internal
    module V1
      class DoctorAvailabilityController < BaseController
        MAX_PERIOD_DAYS = 31

        def show
          doctor = Doctor.find(params[:doctor_id])
          package = Package.find(params.require(:package_id))
          date_from, date_to = requested_period
          timezone = params[:timezone].presence || "America/Mexico_City"

          dates = Api::Internal::V1::AvailabilityCalculator.new(
            doctor: doctor,
            package: package,
            date_from: date_from,
            date_to: date_to,
            timezone: timezone
          ).call

          render_success(
            data: {
              doctor_id: doctor.id,
              package_id: package.id,
              timezone: timezone,
              duration_minutes: package.duration,
              dates: dates
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
            params[:date_to].presence || date_from.iso8601,
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