class Appointment < ApplicationRecord
    belongs_to :package
    belongs_to :doctor

    before_create :generate_unique_code

    # Ensure these fields are always present
    validates :name, :age, :phone, presence: true

    # Custom validation for either email or phone
    #validate :email_or_phone_present


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



end
