# frozen_string_literal: true

module Appointments
  Result = Struct.new(:success?, :appointment, :start_date, :error, keyword_init: true)

  class Create
    def self.call(params:, package:, caller_role: :use)
      return Result.new(success?: false, error: "The selected package could not be found.") unless package

      # Doctor
      doctor_id = params[:doctor_id]
      doctor    = Doctor.find_by(id: doctor_id)
      return Result.new(success?: false, error: "Selected doctor not found.") unless doctor

      # Fecha/hora
      begin
        start_date = Time.zone.parse(params[:start_date].to_s)
      rescue
        start_date = nil
      end
      return Result.new(success?: false, error: "Invalid start date/time.") unless start_date

      duration = package.duration.to_i
      end_date = start_date + duration.minutes

      # Disponibilidad
      unless Availability::SlotFree.call(doctor_id: doctor.id, start_date: start_date)
        return Result.new(
          success?: false,
          start_date: start_date,
          error: "The selected time is no longer available. Please choose a different time."
        )
      end

      # Persistencia
      appt = Appointment.new(params.merge(start_date: start_date, end_date: end_date, status: "scheduled"))
      if appt.save
        event_id = GoogleCalendar::Events::Create.call(
          appointment: appt,
          package:     package,
          doctor_name: Doctor.find(doctor_id)&.name,
          caller_role: caller_role
        )
        puts event_id
        puts appt.inspect
        appt.update_column(:google_calendar_id, event_id) if event_id.present?
        Result.new(success?: true, appointment: appt, start_date: start_date)
      else
        Result.new(success?: false, start_date: start_date, error: appt.errors.full_messages.to_sentence)
      end
    end
  end
end
