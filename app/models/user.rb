class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  enum :role, { admin: "admin", assistant: "assistant", doctor: "doctor" }
  has_one :doctor, dependent: :nullify
  has_many :created_appointments,
           class_name: "Appointment",
           foreign_key: :created_by_id,
           dependent: :nullify,
           inverse_of: :created_by
  has_many :created_phone_bans,
           class_name: "PhoneBan",
           foreign_key: :created_by_id,
           dependent: :nullify,
           inverse_of: :created_by
  
  validates :phone, presence: true

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= "assistant"
  end

  def can_manage_results?
    admin? || doctor? || (assistant? && can_upload_results?)
  end
end
