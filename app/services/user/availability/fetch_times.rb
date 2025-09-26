# frozen_string_literal: true

module User::Availability
  class FetchTimes
    # Devuelve Array<ActiveSupport::TimeWithZone> con inicios de slot disponibles.
    def self.call(doctor:, date:, duration:, timezone: "America/Mexico_City", lead_minutes: 0)
      return [] if doctor.nil?

      dur = duration.to_i
      return [] if dur <= 0

      day = date.is_a?(Date) ? date : Date.parse(date.to_s)


      Time.use_zone(timezone) do
        day_scope = Appointment.where(doctor_id: doctor.id, start_date: day.all_day)
        return [] if day_scope.where(dummy: true).exists?


        hours_map = normalize_hours_map(doctor.available_hours)
        day_keys  = day_name_candidates(day)
        specs     = first_present(hours_map, day_keys)
        return [] if specs.blank?
        specs = Array(specs)

        existing_rows = day_scope.where(status: :scheduled).pluck(:start_date, :end_date, :duration)
        existing = existing_rows.map do |s, e, d|
          e ||= (s && (s + (d.to_i > 0 ? d.to_i : dur).minutes))
          [ s, e ]
        end.compact.select { |s, e| s && e && s < e }

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
              overlap = existing.any? { |s, e| t < e && slot_end > s }
              slots << t unless overlap
            end
            t += dur.minutes
          end
        end

        slots.sort
      end
    rescue ArgumentError
      []
    end

    # helpers

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
      es = %w[domingo lunes martes miércoles jueves sábado][day.wday]
      [ normalize_key(en), normalize_key(es), es.downcase ].uniq
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
