# app/models/doctor_unavailability.rb
class DoctorUnavailability < ApplicationRecord
  belongs_to :doctor

  validates :date, presence: true
  validates :date, uniqueness: { scope: :doctor_id }
end
