# app/services/user/availability/fetch_times.rb
# frozen_string_literal: true

module User::Availability
  class FetchTimes
    # Devuelve Array<ActiveSupport::TimeWithZone> con inicios de slot disponibles.
    #
    # - doctor.available_hours: Hash estilo {"Monday"=>["09:00-17:00"], ...}
    # - DoctorUnavailability: bloqueos día completo (date)
    # - DoctorTimeBlock: bloqueos recurrentes por hora (ej. comida)
    #
    def self.call(doctor:, date:, duration:, timezone: "America/Mexico_City", lead_minutes: 0)
      return [] if doctor.nil?

      dur = duration.to_i
      return [] if dur <= 0

      day = date.is_a?(Date) ? date : Date.parse(date.to_s)

      Time.use_zone(timezone) do
        # =============================
        # 1) Bloqueo día completo
        # =============================
        return [] if DoctorUnavailability.exists?(doctor_id: doctor.id, date: day)

        # =============================
        # 2) Horario laboral del doctor
        # =============================
        hours_map = normalize_hours_map(doctor.available_hours)
        day_keys  = day_name_candidates(day)
        specs     = first_present(hours_map, day_keys)
        return [] if specs.blank?
        specs = Array(specs)

        # =============================
        # 3) Citas existentes (traslapes)
        # =============================
        day_scope = Appointment.where(doctor_id: doctor.id, start_date: day.all_day)

        existing_rows = day_scope.where(status: :scheduled).pluck(:start_date, :end_date, :duration)
        existing = existing_rows.map do |s, e, d|
          next nil if s.blank?
          e ||= s + ((d.to_i > 0 ? d.to_i : dur).minutes)
          [ s, e ]
        end.compact.select { |s, e| s && e && s < e }

        # =============================
        # 4) Bloqueos recurrentes por hora (comida, juntas, etc.)
        # =============================
        # days_of_week usa wday de Ruby: 0=Domingo..6=Sábado
        blocks = doctor.respond_to?(:doctor_time_blocks) ? doctor.doctor_time_blocks.to_a : []

        blocked_intervals = blocks.map do |b|
          next nil if b.starts_at.blank? || b.ends_at.blank?

          # solo aplica si ese bloque incluye este día
          b_days = Array(b.days_of_week).map(&:to_i)
          next nil unless b_days.include?(day.wday)

          start_hhmm = b.starts_at.strftime("%H:%M")
          end_hhmm   = b.ends_at.strftime("%H:%M")

          b_start = Time.zone.parse("#{day} #{start_hhmm}")
          b_end   = Time.zone.parse("#{day} #{end_hhmm}")
          next nil if b_start.blank? || b_end.blank?

          # si el bloque cruza medianoche (raro, pero posible), lo extendemos al día siguiente
          b_end += 1.day if b_end <= b_start

          [ b_start, b_end ]
        end.compact

        # =============================
        # 5) Generación de slots
        # =============================
        now_with_lead = Time.zone.now + lead_minutes.to_i.minutes
        slots = []

        specs.each do |spec|
          next if spec.blank? || !spec.include?("-")

          start_str, end_str = spec.split("-", 2).map(&:strip)
          start_time = parse_hhmm(day, start_str)
          end_time   = parse_hhmm(day, end_str)
          next unless start_time && end_time && start_time < end_time

          t = start_time

          while t < end_time
            slot_end = t + dur.minutes

            if t >= now_with_lead && slot_end <= end_time
              # traslape con citas existentes
              overlap_appt = existing.any? { |s, e| t < e && slot_end > s }

              # traslape con bloqueos recurrentes (comida, etc.)
              overlap_block = blocked_intervals.any? { |s, e| t < e && slot_end > s }

              slots << t unless overlap_appt || overlap_block
            end

            t += dur.minutes
          end
        end

        slots.sort
      end
    rescue ArgumentError
      []
    end

    # =============================
    # Helpers
    # =============================

    def self.normalize_hours_map(raw)
      map = (raw || {})
      map = map.respond_to?(:to_h) ? map.to_h : map
      map.transform_keys { |k| normalize_key(k) }
    end
    private_class_method :normalize_hours_map

    def self.normalize_key(k)
      s = k.to_s.strip.downcase
      s.tr("áéíóúüñ", "aeiouun")
    end
    private_class_method :normalize_key

    def self.day_name_candidates(day)
      en = %w[sunday monday tuesday wednesday thursday friday saturday][day.wday]
      es = %w[domingo lunes martes miercoles jueves viernes sabado][day.wday]

      [ normalize_key(en), normalize_key(es), es.to_s.downcase ].reject(&:blank?).uniq
    end
    private_class_method :day_name_candidates

    def self.first_present(hash, keys)
      keys.each { |k| return hash[k] if hash[k].present? }
      nil
    end
    private_class_method :first_present

    def self.parse_hhmm(day, hhmm)
      Time.zone.parse("#{day} #{hhmm}")
    rescue
      nil
    end
    private_class_method :parse_hhmm
  end
end
