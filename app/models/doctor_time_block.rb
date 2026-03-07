# app/models/doctor_time_block.rb
class DoctorTimeBlock < ApplicationRecord
  belongs_to :doctor

  validates :starts_at, :ends_at, presence: true
  validates :days_of_week, presence: true
  validate :ends_after_starts

  def days_of_week
    Array(super).map(&:to_i)
  end

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "debe ser mayor que la hora inicio") if ends_at <= starts_at
  end
end
