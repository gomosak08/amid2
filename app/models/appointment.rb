class Appointment < ApplicationRecord
  belongs_to :package
  belongs_to :doctor

  enum scheduled_by: { patient: 0, admin: 1 }

  before_create :generate_unique_code
  before_create :generate_token
  before_validation :ensure_token, on: :create

  validates :name, :age, :phone, presence: true
  validates :token, presence: true, uniqueness: true
  validates :google_calendar_id, uniqueness: true, allow_nil: true
  validate :doctor_can_deliver_package, if: -> { doctor && package }

  enum status: {
    scheduled:          0,
    canceled_by_admin:  1,
    canceled_by_client: 2,
    completed:          3
  }

  def scheduled_by_label
    case scheduled_by
    when "patient" then "Paciente"
    when "admin"   then "Administrador"
    else scheduled_by.humanize
    end
  end

  def status_label
    case status
    when "scheduled"         then "Programada"
    when "canceled_by_admin" then "Cancelada por Admin"
    when "canceled_by_client"then "Cancelada por Cliente"
    when "completed"         then "Completada"
    else status.humanize
    end
  end

  def to_param
    token.presence || super
  end

  # Validaciones de negocio
  validate :no_double_booking

  private

  def no_double_booking
    overlapping_appointment = Appointment
      .where(doctor_id: doctor_id)
      .where(start_date: start_date)
      .where.not(id: id)

    if overlapping_appointment.exists?
      errors.add(:start_date, "ya está ocupado para este doctor.")
    end
  end

  def doctor_can_deliver_package
    unless doctor.packages.exists?(id: package_id)
      errors.add(:doctor_id, "no puede atender el paquete seleccionado")
    end
  end

  def generate_unique_code
    self.unique_code = SecureRandom.alphanumeric(8).upcase
  end

  def ensure_token
    self.token ||= SecureRandom.hex(16) # 32 chars
  end

  def generate_token
    self.token = SecureRandom.hex(16)
  end
end
