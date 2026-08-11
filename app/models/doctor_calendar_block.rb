class DoctorCalendarBlock < ApplicationRecord
  belongs_to :doctor

  scope :active, -> { where(canceled_at: nil) }
  scope :overlapping, ->(starts_at, ends_at) {
    where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
  }

  validates :starts_at, :ends_at, presence: true
  validates :api_idempotency_key, uniqueness: true, allow_blank: true
  validate :ends_after_start

  private

  def ends_after_start
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "debe ser posterior a starts_at")
  end
end