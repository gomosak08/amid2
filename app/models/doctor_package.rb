class DoctorPackage < ApplicationRecord
  belongs_to :doctor
  belongs_to :package

  validates :doctor_id, uniqueness: { scope: :package_id }
end
