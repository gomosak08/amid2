# app/services/availability/fetch_times.rb
# frozen_string_literal: true

module Availability
  class FetchTimes
    # Devuelve Array<ActiveSupport::TimeWithZone> con los inicios de slot disponibles
    # - doctor.available_hours[day_name] puede ser "09:00-17:00" o Array de rangos ["09:00-12:00","13:00-17:00"]
    # - duration en minutos
    # - timezone por defecto CDMX
    def self.call(doctor:, date:, duration:, timezone: "America/Mexico_City")
      return [] if doctor.nil?

      dur = duration.to_i
      return [] if dur <= 0

      day = date.is_a?(Date) ? date : Date.parse(date.to_s)

      Time.use_zone(timezone) do
        # 1) Bloquea si hay "dummy appointments" en ese día
        return [] if Appointment.where(doctor_id: doctor.id, start_date: day.all_day, dummy: true).exists?

        # 2) Obtén horario disponible del doctor para ese día de la semana
        day_name = day.strftime("%A") # "Monday", etc.
        hours_map = (doctor.available_hours || {})
        hours_map = hours_map.respond_to?(:to_h) ? hours_map.to_h : hours_map
        hours_map = hours_map.transform_keys(&:to_s)
        specs = Array(hours_map[day_name]) # puede ser nil, String o Array<String>
        return [] if specs.blank?

        # 3) Appointments existentes ese día
        existing = Appointment
          .where(doctor_id: doctor.id, status: :scheduled)
          .where(start_date: day.all_day)
          .pluck(:start_date, :end_date)

        now   = Time.zone.now
        slots = []

        # 4) Genera slots por cada rango "HH:MM-HH:MM"
        specs.each do |spec|
          next if spec.blank? || !spec.include?("-")
          start_str, end_str = spec.split("-", 2).map(&:strip)
          start_time = Time.zone.parse("#{day} #{start_str}")
          end_time   = Time.zone.parse("#{day} #{end_str}")
          next unless start_time && end_time && start_time < end_time

          t = start_time
          while t < end_time
            if t >= now
              overlap = existing.any? { |s, e| t < e && (t + dur.minutes) > s }
              slots << t unless overlap
            end
            t += dur.minutes
          end
        end

        slots.sort
      end
    rescue ArgumentError
      [] # por si el date no parsea
    end
  end
end
