class Appointment < ApplicationRecord
  belongs_to :package
  belongs_to :doctor
  has_many_attached :study_results

  before_validation :ensure_unique_code, on: :create
  before_validation :ensure_token, on: :create
  before_validation :normalize_phone_number

  after_create_commit :schedule_whatsapp_notifications

  validates :name, :age, :phone, presence: true
  validates :token, presence: true, uniqueness: true
  validates :unique_code, presence: true, uniqueness: true
  validates :google_calendar_id, uniqueness: true, allow_nil: true

  validate :doctor_can_deliver_package, if: -> { doctor && package }
  validate :phone_not_banned, on: :create
  validate :no_double_booking
  validate :doctor_not_unavailable, if: -> { doctor && start_date }

  enum :scheduled_by, {
    patient: 0,
    admin: 1
  }

  enum :status, {
    scheduled: 0,
    canceled_by_admin: 1,
    canceled_by_client: 2,
    completed: 3,
    no_show: 4
  }

  def to_param
    token.presence || super
  end

  def scheduled_by_label
    case scheduled_by
    when "patient" then "Paciente"
    when "admin"   then "Administrador"
    else scheduled_by.humanize
    end
  end

  def status_label
    case status
    when "scheduled"          then "Programada"
    when "canceled_by_admin"  then "Cancelada por Admin"
    when "canceled_by_client" then "Cancelada por Cliente"
    when "completed"          then "Completada"
    when "no_show"            then "No Asistió"
    else status.humanize
    end
  end

  def normalize_phone_number
    raw_phone =
      if respond_to?(:phone_number) && phone_number.present?
        phone_number
      elsif respond_to?(:phone) && phone.present?
        phone
      end

    self.phone_number_e164 = PhoneNormalizer.to_e164(raw_phone) if respond_to?(:phone_number_e164=)
  end

  def phone_not_banned
    return unless respond_to?(:phone_number_e164)
    return if phone_number_e164.blank?

    ban = PhoneBan.active_now.find_by(phone_e164: phone_number_e164)
    return if ban.blank?

    if ban.hard?
      errors.add(:base, "Este número no puede agendar ni contactar asistencia.")
    else
      errors.add(:base, "Este número no puede agendar en línea. Debe hacerlo con un asistente.")
    end
  end

  def doctor_not_unavailable
    if DoctorUnavailability.exists?(doctor_id: doctor_id, date: start_date.to_date)
      errors.add(:start_date, "el doctor no está disponible ese día.")
    end
  end

  private

  def schedule_whatsapp_notifications
    raw_phone =
      if respond_to?(:phone_number) && phone_number.present?
        phone_number
      elsif phone.present?
        phone
      end

    return if raw_phone.blank?
    return unless start_date.present?

    target_phone =
      if respond_to?(:phone_number_e164) && phone_number_e164.present?
        phone_number_e164
      else
        raw_phone
      end

    now = Time.current
    time_until_appointment = start_date - now

    Rails.logger.info "[WA SCHEDULER] Appointment ##{id} start_date=#{start_date} now=#{now} diff_seconds=#{time_until_appointment}"

    # 1) Confirmación inmediata
    SendWhatsappMessageJob.perform_later(
      to: target_phone,
      message_type: "confirmation",
      appointment_id: id
    )

    # 2) Primer recordatorio
    # - Si faltan más de 24h: mandar 24h antes
    # - Si faltan menos de 24h pero más de 2h: mandar inmediato
    if time_until_appointment > 24.hours
      reminder_24h_at = start_date - 24.hours

      SendWhatsappMessageJob.set(wait_until: reminder_24h_at).perform_later(
        to: target_phone,
        message_type: "reminder_24h",
        appointment_id: id
      )

      Rails.logger.info "[WA SCHEDULER] reminder_24h agendado para #{reminder_24h_at} appointment_id=#{id}"
    elsif time_until_appointment > 2.hours
      SendWhatsappMessageJob.perform_later(
        to: target_phone,
        message_type: "reminder_24h",
        appointment_id: id
      )

      Rails.logger.info "[WA SCHEDULER] reminder_24h enviado inmediato appointment_id=#{id}"
    else
      Rails.logger.info "[WA SCHEDULER] reminder_24h no aplica appointment_id=#{id}"
    end

    # 3) Segundo recordatorio 2h antes
    # Solo si la cita se agenda con más de 2 horas de anticipación
    if time_until_appointment > 2.hours
      reminder_2h_at = start_date - 2.hours

      SendWhatsappMessageJob.set(wait_until: reminder_2h_at).perform_later(
        to: target_phone,
        message_type: "reminder_2h",
        appointment_id: id
      )

      Rails.logger.info "[WA SCHEDULER] reminder_2h agendado para #{reminder_2h_at} appointment_id=#{id}"
    else
      Rails.logger.info "[WA SCHEDULER] reminder_2h no aplica appointment_id=#{id}"
    end
  end

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

  def ensure_unique_code
    return if unique_code.present?

    loop do
      self.unique_code = SecureRandom.alphanumeric(8).upcase
      break unless self.class.exists?(unique_code: unique_code)
    end
  end

  def ensure_token
    return if token.present?

    loop do
      self.token = SecureRandom.hex(16)
      break unless self.class.exists?(token: token)
    end
  end
end
