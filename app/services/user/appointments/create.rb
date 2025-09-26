# frozen_string_literal: true

module User::Appointments
  Result = Struct.new(:success?, :appointment, :start_date, :error, keyword_init: true)

  class Create
    def self.call(params:, package:, caller_role: :user)
      return Result.new(success?: false, error: "No se encontró el paquete seleccionado.") unless package

      # Doctor
      doctor_id = params[:doctor_id]
      doctor    = Doctor.find_by(id: doctor_id)
      return Result.new(success?: false, error: "No se encontró el médico seleccionado.") unless doctor

      # Fecha/hora
      begin
        start_date = Time.zone.parse(params[:start_date].to_s)
      rescue
        start_date = nil
      end
      return Result.new(success?: false, error: "Fecha y hora inválidas.") unless start_date

      duration = package.duration.to_i
      end_date = start_date + duration.minutes

      # Disponibilidad
      unless User::Availability::SlotFree.call(doctor_id: doctor.id, start_date: start_date)
        return Result.new(
          success?: false,
          start_date: start_date,
          error: "El horario seleccionado ya no está disponible. Por favor, elige otro horario."
        )
      end

      # Persistencia
      appt = Appointment.new(params.merge(start_date: start_date, end_date: end_date, status: "scheduled"))
      if appt.save
        event_id = User::GoogleCalendar::Events::Create.call(
          appointment: appt,
          package:     package,
          doctor_name: Doctor.find(doctor_id)&.name,
          caller_role: caller_role
        )

        appt.update_column(:google_calendar_id, event_id) if event_id.present?
        appt.update_column(:scheduled_by, (%w[admin secretary].include?(caller_role.to_s) ? :admin : :patient))
        Result.new(success?: true, appointment: appt, start_date: start_date)
      else
        Result.new(success?: false, start_date: start_date, error: appt.errors.full_messages.to_sentence)
      end
    end
  end
end
