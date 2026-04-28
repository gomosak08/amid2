# app/services/user/availability/slot_free.rb
# frozen_string_literal: true

module User::Availability
  class SlotFree
    def self.call(doctor_id:, start_date:, duration: 30)
      doctor = Doctor.find_by(id: doctor_id)
      return false unless doctor && start_date

      # Delegar al servicio central FetchTimes que considera:
      # - Horario de oficina
      # - Bloqueos de día completo
      # - Bloqueos de horas específicas
      # - Bloqueos recurrentes semanales
      # - Citas superpuestas existentes
      times = User::Availability::FetchTimes.call(
        doctor: doctor, 
        date: start_date.to_date, 
        duration: duration
      )

      times.include?(start_date)
    end
  end
end
