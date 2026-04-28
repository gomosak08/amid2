# frozen_string_literal: true

module User::Appointments
  Result = Struct.new(:success?, :appointment, :start_date, :error, keyword_init: true)

  class Create
    def self.call(params:, package:, caller_role: :user, caller_user: nil)
      return Result.new(success?: false, error: "No se encontró el paquete seleccionado.") unless package

      doctors = if package.respond_to?(:doctors) && package.doctors.exists?
                  package.doctors
                else
                  Doctor.all
                end

      # Teléfono normalizado
      phone_e164 = PhoneNormalizer.to_e164(params[:phone])

      # Doctor: respeta selección manual; si no viene, usa médico habitual por teléfono o uno al azar.
      doctor = resolve_doctor(params[:doctor_id], phone_e164, doctors)
      return Result.new(success?: false, error: "No se encontró un médico disponible para el paquete seleccionado.") unless doctor

      unless doctors.exists?(id: doctor.id)
        return Result.new(success?: false, error: "El médico seleccionado no atiende el paquete elegido.")
      end

      # Fecha/hora
      begin
        start_date = Time.zone.parse(params[:start_date].to_s)
      rescue StandardError
        start_date = nil
      end
      return Result.new(success?: false, error: "Fecha y hora inválidas.") unless start_date

      duration = package.duration.to_i
      end_date = start_date + duration.minutes

      # Baneo por teléfono
      phone_ban = PhoneBan.active_now.find_by(phone_e164: phone_e164)

      if phone_ban.present?
        if phone_ban.hard?
          return Result.new(
            success?: false,
            start_date: start_date,
            error: "Este número no puede agendar ni contactar a un asistente."
          )
        end

        if phone_ban.soft? && caller_role.to_sym == :user
          return Result.new(
            success?: false,
            start_date: start_date,
            error: "Este número no puede agendar en línea. Debe hacerlo con un asistente."
          )
        end
      end

      # Disponibilidad
      unless User::Availability::SlotFree.call(doctor_id: doctor.id, start_date: start_date, duration: duration)
        return Result.new(
          success?: false,
          start_date: start_date,
          error: "El horario seleccionado ya no está disponible. Por favor, elige otro horario."
        )
      end

      # Persistencia
      appt = Appointment.new(
        params.merge(
          phone: phone_e164,
          doctor_id: doctor.id,
          start_date: start_date,
          end_date: end_date,
          status: "scheduled",
          created_by: caller_user
        )
      )

      if appt.save
        event_id = User::GoogleCalendar::Events::Create.call(
          appointment: appt,
          package: package,
          doctor_name: doctor.name,
          caller_role: caller_role
        )

        sched_by = if caller_role.to_s == "assistant"
                     :assistant
                   elsif caller_role.to_s == "admin"
                     :admin
                   elsif caller_role.to_s == "general_user"
                     :general_user
                   else
                     :patient
                   end

        appt.update_column(:google_calendar_id, event_id) if event_id.present?
        appt.update_column(:scheduled_by, sched_by)

        Result.new(success?: true, appointment: appt, start_date: start_date)
      else
        Result.new(success?: false, start_date: start_date, error: appt.errors.full_messages.to_sentence)
      end
    end

    def self.resolve_doctor(selected_doctor_id, phone_e164, doctors)
      if selected_doctor_id.present?
        return doctors.find_by(id: selected_doctor_id)
      end

      preferred = preferred_doctor_for(phone_e164, doctors)
      return preferred if preferred

      doctors.to_a.sample
    end
    private_class_method :resolve_doctor

    def self.preferred_doctor_for(phone_e164, doctors)
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
