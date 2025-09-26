# app/services/forms/appointment_form_context.rb
# frozen_string_literal: true

module User::Forms
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

      package  = Package.find_by(id: pkg_id)
      duration = (package&.duration || params.dig(:appointment, :duration)).to_i

      # 👇 Filtra doctores por paquete (si hay paquete); si no, ninguno (o todos, según prefieras)
      doctors = if pkg_id.present?
        Doctor.for_package(pkg_id).order(:name)
      else
        Doctor.none  # o Doctor.all si quieres listar todos cuando no hay paquete
      end

      # 👇 Si vino un doctor preseleccionado pero NO atiende ese paquete, lo limpiamos
      if doctor_id.present? && pkg_id.present? && !doctors.exists?(id: doctor_id)
        doctor_id = nil
      end

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
          available_times = User::Availability::FetchTimes.call(
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
