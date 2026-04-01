# app/models/doctor.rb
class Doctor < ApplicationRecord
  belongs_to :user, optional: true
  accepts_nested_attributes_for :user, reject_if: ->(attrs) { attrs['email'].blank? }

  has_many :appointments, dependent: :destroy

  has_many :doctor_packages
  has_many :packages, through: :doctor_packages

  has_many :doctor_unavailabilities, dependent: :destroy
  has_many :doctor_time_blocks, dependent: :destroy
  scope :for_package, ->(pkg_id) {
    joins(:doctor_packages).where(doctor_packages: { package_id: pkg_id })
  }

  def available_hours
    JSON.parse(super || "{}")
  rescue JSON::ParserError
    {}
  end

  def available_hours=(value)
    super(value.is_a?(String) ? value : value.to_json)
  end

  # ✅ helper: ¿está bloqueado este día?
  def unavailable_on?(date)
    d = date.is_a?(Date) ? date : Date.parse(date.to_s)
    doctor_unavailabilities.exists?(date: d)
  end
end
