class Appointment < ApplicationRecord
  belongs_to :package
  belongs_to :doctor
  belongs_to :created_by, class_name: "User", optional: true

  has_many_attached :study_results

  before_validation :ensure_unique_code, on: :create
  before_validation :ensure_token, on: :create
  before_validation :normalize_phone_number
  before_validation :sync_status_from_clinical_status

  after_create_commit :schedule_whatsapp_notifications

  validates :name, :age, :phone, presence: true
  validates :token, presence: true, uniqueness: true
  validates :unique_code, presence: true, uniqueness: true
  validates :google_calendar_id, uniqueness: true, allow_nil: true

  validate :doctor_can_deliver_package, if: -> { doctor.present? && package.present? }
  validate :phone_not_banned, on: :create
  validate :no_double_booking
  validate :doctor_not_unavailable, if: -> { doctor.present? && start_date.present? }

  enum :scheduled_by, {
    patient: 0,
    admin: 1,
    assistant: 2
  }

  enum :status, {
    scheduled: 0,
    canceled_by_admin: 1,
    canceled_by_client: 2,
    completed: 3,
    no_show: 4
  }

  enum :clinical_status, {
    pending: 0,
    checked_in: 1,
    triaged: 2,
    waiting_for_doctor: 3,
    in_consultation: 4,
    completed: 5
  }, prefix: true

  def to_param
    token.presence || super
  end

  def scheduled_by_label
    if created_by.present?
      user_name =
        created_by.name.presence ||
        created_by.email.to_s.split("@").first.presence ||
        "Usuario"

      role_label =
        case created_by.role
        when "admin"
          "Administrador"
        when "assistant"
          "Asistente"
        when "doctor"
          "Médico"
        else
          "Usuario"
        end

      "#{role_label} - #{user_name}"
    else
      case scheduled_by
      when "patient"
        "Paciente"
      when "admin"
        "Administrador"
      when "assistant"
        "Asistente"
      else
        scheduled_by.present? ? scheduled_by.humanize : "No especificado"
      end
    end
  end

  def status_label
    case status
    when "scheduled"
      "Programada"
    when "canceled_by_admin"
      "Cancelada por Admin"
    when "canceled_by_client"
      "Cancelada por Cliente"
    when "completed"
      "Completada"
    when "no_show"
      "No Asistió"
    else
      status.present? ? status.humanize : "No especificado"
    end
  end

  def normalize_phone_number
    raw_phone =
      if respond_to?(:phone_number) && phone_number.present?
        phone_number
      elsif phone.present?
        phone
      end

    return if raw_phone.blank?
    return unless respond_to?(:phone_number_e164=)

    self.phone_number_e164 = PhoneNormalizer.to_e164(raw_phone)
  end

  def phone_not_banned
    return unless respond_to?(:phone_number_e164)
    return if phone_number_e164.blank?

    ban = PhoneBan.active_now.find_by(phone_e164: phone_number_e164)
    return if ban.blank?

    if ban.hard?
      errors.add(
        :base,
        "Este número no puede agendar ni contactar asistencia."
      )
    else
      errors.add(
        :base,
        "Este número no puede agendar en línea. Debe hacerlo con un asistente."
      )
    end
  end

  def doctor_not_unavailable
    return if doctor_id.blank? || start_date.blank?

    full_day_block =
      DoctorUnavailability
        .where(
          doctor_id: doctor_id,
          date: start_date.to_date,
          start_time: nil,
          end_time: nil
        )

    if full_day_block.exists?
      errors.add(
        :start_date,
        "el doctor no está disponible ese día completo."
      )
    end
  end

  private

  def sync_status_from_clinical_status
    return unless will_save_change_to_clinical_status?
    return unless clinical_status_completed?

    self.status = :completed
  end

  def schedule_whatsapp_notifications
    raw_phone =
      if respond_to?(:phone_number) && phone_number.present?
        phone_number
      elsif phone.present?
        phone
      end

    return if raw_phone.blank?
    return if start_date.blank?

    target_phone =
      if respond_to?(:phone_number_e164) && phone_number_e164.present?
        phone_number_e164
      else
        raw_phone
      end

    now = Time.current
    time_until_appointment = start_date - now

    Rails.logger.info(
      "[WA SCHEDULER] Appointment ##{id} " \
      "start_date=#{start_date} now=#{now} " \
      "diff_seconds=#{time_until_appointment}"
    )

    # 1. Confirmación inmediata
    SendWhatsappMessageJob.perform_later(
      to: target_phone,
      message_type: "confirmation",
      appointment_id: id
    )

    # 2. Recordatorio 24 horas antes
    if time_until_appointment > 24.hours
      reminder_24h_at = start_date - 24.hours

      SendWhatsappMessageJob
        .set(wait_until: reminder_24h_at)
        .perform_later(
          to: target_phone,
          message_type: "reminder_24h",
          appointment_id: id
        )

      Rails.logger.info(
        "[WA SCHEDULER] reminder_24h agendado para " \
        "#{reminder_24h_at} appointment_id=#{id}"
      )
    elsif time_until_appointment > 2.hours
      SendWhatsappMessageJob.perform_later(
        to: target_phone,
        message_type: "reminder_24h",
        appointment_id: id
      )

      Rails.logger.info(
        "[WA SCHEDULER] reminder_24h enviado inmediato " \
        "appointment_id=#{id}"
      )
    else
      Rails.logger.info(
        "[WA SCHEDULER] reminder_24h no aplica appointment_id=#{id}"
      )
    end

    # 3. Recordatorio 2 horas antes
    if time_until_appointment > 2.hours
      reminder_2h_at = start_date - 2.hours

      SendWhatsappMessageJob
        .set(wait_until: reminder_2h_at)
        .perform_later(
          to: target_phone,
          message_type: "reminder_2h",
          appointment_id: id
        )

      Rails.logger.info(
        "[WA SCHEDULER] reminder_2h agendado para " \
        "#{reminder_2h_at} appointment_id=#{id}"
      )
    else
      Rails.logger.info(
        "[WA SCHEDULER] reminder_2h no aplica appointment_id=#{id}"
      )
    end
  end

  def no_double_booking
    return if doctor_id.blank? || start_date.blank?

    overlapping_appointment =
      Appointment
        .where(doctor_id: doctor_id)
        .where(start_date: start_date)
        .where(status: :scheduled)
        .where.not(id: id)

    if overlapping_appointment.exists?
      errors.add(
        :start_date,
        "ya está ocupado para este doctor."
      )
    end
  end

  def doctor_can_deliver_package
    return if doctor.blank? || package_id.blank?

    unless doctor.packages.exists?(id: package_id)
      errors.add(
        :doctor_id,
        "no puede atender el paquete seleccionado"
      )
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