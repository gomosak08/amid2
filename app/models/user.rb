class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  enum role: { admin: "admin", assistant: "assistant", doctor: "doctor" }
  has_one :doctor, dependent: :nullify
  
  validates :phone, presence: true

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= "assistant"
  end

  def can_manage_results?
    admin? || doctor? || (assistant? && can_upload_results?)
  end
end
