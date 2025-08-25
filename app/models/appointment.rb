require "securerandom"
class Appointment < ApplicationRecord
    belongs_to :package
    belongs_to :doctor

    before_create :generate_unique_code
    before_create :generate_token
    # Ensure these fields are always present
    validates :name, :age, :phone, presence: true
    validates :token, presence: true, uniqueness: true

    before_validation :ensure_token, on: :create

    enum status: {
      scheduled:          0,
      canceled_by_admin:  1,
      canceled_by_client: 2
    }

    # Optional: human‐friendly labels for views
    def status_label
      case status
      when "scheduled"         then "Programada"
      when "canceled_by_admin" then "Cancelada por Admin"
      when "canceled_by_client"then "Cancelada por Cliente"
      else status.humanize
      end
    end

    def to_param
      token.presence || super
    end
    # Ensure that appointment times do not overlap for the same doctor
    validate :no_double_booking
    validates :google_calendar_id, uniqueness: true, allow_nil: true
    private


    def no_double_booking
        # Check if any appointment exists for the doctor at the same date and time
        overlapping_appointment = Appointment
        .where(doctor_id: doctor_id)
        .where("start_date = ?", start_date)
        .where.not(id: id) # Exclude the current appointment in case of updates

        if overlapping_appointment.exists?
        errors.add(:start_date, "is already booked for the selected time slot.")
        end
    end

    def email_or_phone_present
        if email.blank? && phone.blank?
          errors.add(:base, "Either email or phone must be provided.")
        end
    end
    def generate_unique_code
      # Generate a random alphanumeric code, e.g., 8 characters long
      self.unique_code = SecureRandom.alphanumeric(8).upcase
    end

    def ensure_token
      self.token ||= SecureRandom.hex(16) # 32 chars hex
    end

    def generate_token
      self.token = SecureRandom.hex(16)
    end
end
