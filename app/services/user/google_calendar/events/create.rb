module User::GoogleCalendar::Events
  class Create
    def self.call(appointment:, package:, doctor_name:, calendar_id: "primary",
                  timezone: "America/Mexico_City", color_id: nil, caller_role: :user, emoji: nil)

      unless ENV["GOOGLE_CALENDAR_ENABLED"] == "1"
        Rails.logger.warn("[GCal] Deshabilitado por flag GOOGLE_CALENDAR_ENABLED")
        return nil
      end

      require "google/apis/calendar_v3"
      # require "googleauth" # no necesario si tu Client usa signet

      # --- Cliente ---
      service = User::GoogleCalendar::Client.build
      unless service
        Rails.logger.error("[GCal] Cliente no disponible (credenciales/refresh token ausente)")
        return nil
      end

      # --- Fechas ---
      start_time = appointment.start_date
      end_time   = appointment.end_date || (start_time && start_time + (appointment.respond_to?(:duration) ? appointment.duration.to_i : package.duration.to_i).minutes)
      if start_time.blank? || end_time.blank?
        Rails.logger.error("[GCal] Fechas inválidas: start=#{start_time.inspect} end=#{end_time.inspect} appt_id=#{appointment.id}")
        return nil
      end

      # --- Apariencia ---
      color_id ||= ((appointment.doctor_id.to_i % 11) + 1).to_s
      emoji    ||= (caller_role.to_s == "admin" ? "💻" : caller_role.to_s == "user" ? "👤" : "🗓")
      title      = "#{emoji} #{package&.name || 'Consulta'} con #{doctor_name}"

      event = Google::Apis::CalendarV3::Event.new(
        summary: title,
        description: [
          ("Paciente: #{appointment.name}"       if appointment.respond_to?(:name)        && appointment.name.present?),
          ("Teléfono: #{appointment.phone}"      if appointment.respond_to?(:phone)       && appointment.phone.present?),
          ("Código: #{appointment.unique_code}"  if appointment.respond_to?(:unique_code) && appointment.unique_code.present?)
        ].compact.join("\n"),
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_time.iso8601, time_zone: timezone),
        end:   Google::Apis::CalendarV3::EventDateTime.new(date_time: end_time.iso8601,   time_zone: timezone),
        color_id: color_id
      )

      Rails.logger.info("[GCal] Insertando evento calendar_id=#{calendar_id} appt_id=#{appointment.id} doctor_id=#{appointment.doctor_id} start=#{start_time} end=#{end_time} tz=#{timezone} title=#{title.inspect}")

      created = service.insert_event(calendar_id, event)
      Rails.logger.info("[GCal] Evento creado id=#{created&.id} appt_id=#{appointment.id}")
      created&.id

    rescue Google::Apis::ClientError => e
      Rails.logger.error("[GCal] ClientError #{e.status_code} appt_id=#{appointment.id} msg=#{e.message} body=#{(e.respond_to?(:body) ? e.body : nil)}")
      raise if Rails.env.development? # en dev, prefiero ver el stacktrace
      nil
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error("[GCal] AuthorizationError appt_id=#{appointment.id} msg=#{e.message}")
      raise if Rails.env.development?
      nil
    rescue Google::Apis::ServerError => e
      Rails.logger.error("[GCal] ServerError appt_id=#{appointment.id} msg=#{e.message}")
      raise if Rails.env.development?
      nil
    rescue NameError => e
      Rails.logger.error("[GCal] NameError: #{e.message} (¿namespace correcto? usa User::GoogleCalendar::Client)")
      raise if Rails.env.development?
      nil
    rescue StandardError => e
      Rails.logger.error("[GCal] #{e.class}: #{e.message}\n#{e.backtrace.take(5).join("\n")}")
      raise if Rails.env.development?
      nil
    end
  end
end
