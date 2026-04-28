# app/services/forms/appointment_form_context.rb
# frozen_string_literal: true

module User::Forms
  class AppointmentFormContext
    Context = Struct.new(
      :appointment, :package, :duration, :doctors, :doctor_id, :appointment_date, :available_times,
      :patient_name, :patient_age, :patient_phone, :preferred_doctor_id, :doctor_assignment_reason,
      :time_slot, :available_doctors, :week_availability,
      keyword_init: true
    )

    def self.call(params:, appointment: nil)
      pkg_id     = params[:package_id] || params.dig(:appointment, :package_id)
      doctor_id  = params[:doctor_id]  || params.dig(:appointment, :doctor_id)
      time_slot = params[:time_slot].presence || params.dig(:appointment, :start_date).presence
      patient_name = params[:name].presence || params.dig(:appointment, :name).presence
      patient_age = params[:age].presence || params.dig(:appointment, :age).presence
      patient_phone = params[:phone].presence || params.dig(:appointment, :phone).presence
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

      preferred_doctor_id = preferred_doctor_for(patient_phone, doctors)&.id
      appt_date = begin
        if date_param.present?
          t = Time.zone.parse(date_param.to_s) rescue nil
          t ? t.to_date : Date.parse(date_param.to_s)
        end
      rescue
        nil
      end

      appointment ||= Appointment.new
      appointment.assign_attributes(
        name: patient_name,
        age: patient_age,
        phone: patient_phone,
        package: package
      )

      available_times_by_doctor = {}
      available_times = []

      if appt_date.present? && duration.positive?
        doctors.each do |doctor|
          times = User::Availability::FetchTimes.call(doctor:, date: appt_date, duration:)
          available_times_by_doctor[doctor.id] = times
          available_times.concat(times)
        end
      end

      available_times = unique_times(available_times)
      selected_time = parse_time_slot(time_slot)
      available_doctors = doctors_for_time(doctors, available_times_by_doctor, selected_time)

      if doctor_id.blank? && selected_time.present? && preferred_doctor_id.present?
        doctor_id = preferred_doctor_id if available_doctors.exists?(id: preferred_doctor_id)
      end

      assignment_reason =
        if doctor_id.present? && preferred_doctor_id.present?
          doctor_id.to_i == preferred_doctor_id.to_i ? :habitual : :cambio_habitual
        elsif preferred_doctor_id.present?
          :habitual
        end

      Context.new(
        appointment:      appointment,
        package:          package,
        duration:         duration,
        doctors:          doctors,
        doctor_id:        doctor_id,
        appointment_date: appt_date,
        available_times:  available_times,
        patient_name:     patient_name,
        patient_age:      patient_age,
        patient_phone:    patient_phone,
        preferred_doctor_id: preferred_doctor_id,
        doctor_assignment_reason: assignment_reason,
        time_slot:        selected_time&.iso8601,
        available_doctors: available_doctors,
        week_availability: week_availability(doctors, appt_date || Date.current, duration)
      )
    end

    def self.unique_times(times)
      times
        .compact
        .uniq { |time| time.to_i }
        .sort
    end
    private_class_method :unique_times

    def self.parse_time_slot(time_slot)
      return nil if time_slot.blank?

      Time.zone.parse(time_slot.to_s)
    rescue StandardError
      nil
    end
    private_class_method :parse_time_slot

    def self.doctors_for_time(doctors, available_times_by_doctor, selected_time)
      return Doctor.none if selected_time.blank?

      ids = available_times_by_doctor.select do |_doctor_id, times|
        times.any? { |time| time.to_i == selected_time.to_i }
      end.keys

      doctors.where(id: ids)
    end
    private_class_method :doctors_for_time

    def self.week_availability(doctors, selected_date, duration)
      base = selected_date.is_a?(Date) ? selected_date : Date.parse(selected_date.to_s)
      week_start = base.beginning_of_week(:monday)

      (week_start..(week_start + 6.days)).map do |day|
        doctors_with_availability = 0
        all_times = []

        doctors.each do |doctor|
          times = User::Availability::FetchTimes.call(doctor:, date: day, duration:)
          next if times.blank?

          doctors_with_availability += 1
          all_times.concat(times)
        end

        unique_day_times = unique_times(all_times)

        {
          date: day,
          doctors_count: doctors_with_availability,
          slots_count: unique_day_times.size,
          times: unique_day_times
        }
      end
    rescue StandardError
      []
    end
    private_class_method :week_availability

    def self.preferred_doctor_for(phone, doctors)
      phone_e164 = PhoneNormalizer.to_e164(phone)
      return nil if phone_e164.blank?

      scope = Appointment.where.not(doctor_id: nil).order(start_date: :desc, created_at: :desc)

      appointment =
        if Appointment.column_names.include?("phone_number_e164")
          scope.find_by(phone_number_e164: phone_e164)
        end

      appointment ||= scope.find_by(phone: phone_e164)
      return nil unless appointment

      doctors.find_by(id: appointment.doctor_id)
    end
    private_class_method :preferred_doctor_for
  end
end
