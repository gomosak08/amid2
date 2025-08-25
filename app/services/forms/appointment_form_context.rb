# app/services/forms/appointment_form_context.rb
# frozen_string_literal: true

module Forms
  class AppointmentFormContext
    Context = Struct.new(
      :appointment, :package, :duration, :doctors, :doctor_id, :appointment_date, :available_times,
      keyword_init: true
    )

    def self.call(params:, appointment: nil)
      pkg_id     = params[:package_id] || params.dig(:appointment, :package_id)
      doctor_id  = params[:doctor_id]  || params.dig(:appointment, :doctor_id)
      date_param = params[:appointment_date] ||
                   params.dig(:appointment, :appointment_date) ||
                   params.dig(:appointment, :start_date)

      package   = Package.find_by(id: pkg_id)
      duration  = (package&.duration || params.dig(:appointment, :duration)).to_i
      doctors   = Doctor.all

      appt_date = begin
        if date_param.present?
          t = Time.zone.parse(date_param.to_s) rescue nil
          t ? t.to_date : Date.parse(date_param.to_s)
        end
      rescue
        nil
      end

      available_times = []
      if doctor_id.present? && appt_date.present? && duration.positive?
        if (doctor = Doctor.find_by(id: doctor_id))
          available_times = Availability::FetchTimes.call(
            doctor:, date: appt_date, duration:
          )
        end
      end

      Context.new(
        appointment:      appointment || Appointment.new,
        package:          package,
        duration:         duration,
        doctors:          doctors,
        doctor_id:        doctor_id,
        appointment_date: appt_date,
        available_times:  available_times
      )
    end
  end
end
