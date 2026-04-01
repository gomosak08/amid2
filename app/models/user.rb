class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  enum role: { admin: "admin", secretary: "secretary", medic: "medic" }
  has_one :doctor, dependent: :nullify

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= "secretary"
  end

  def can_manage_results?
    admin? || medic? || (secretary? && can_upload_results?)
  end
end
