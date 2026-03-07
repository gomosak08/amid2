class PhoneBan < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  enum :level, { soft: 0, hard: 1 }
  enum :source, { manual: 0, automatic: 1 }

  validates :phone_e164, presence: true, uniqueness: true
  validates :reason, presence: true

  scope :active_now, -> {
    where(active: true)
      .where("expires_at IS NULL OR expires_at > ?", Time.current)
  }

  def active_now?
    active && (expires_at.nil? || expires_at > Time.current)
  end
end
