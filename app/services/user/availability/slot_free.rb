# app/services/user/availability/slot_free.rb
# frozen_string_literal: true

module User::Availability
  class SlotFree
    def self.call(doctor_id:, start_date:)
      doctor = Doctor.find_by(id: doctor_id)
      return false unless doctor && start_date

      day = start_date.to_date

      # ✅ si el día está bloqueado, no está libre
      return false if DoctorUnavailability.exists?(doctor_id: doctor.id, date: day)

      # Ocupado si hay cita que se traslape
      Appointment.where(doctor_id: doctor.id, status: :scheduled)
                 .where("start_date < ? AND end_date > ?", start_date + 1.second, start_date)
                 .none?
    end
  end
end
