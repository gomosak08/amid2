class SendWhatsappMessageJob < ApplicationJob
  queue_as :default

  def perform(to:, message_type:, appointment_id:)
    Rails.logger.info "[WA JOB] Iniciando envío to=#{to} message_type=#{message_type} appointment_id=#{appointment_id}"

    appointment = Appointment.includes(:doctor, :package).find_by(id: appointment_id)
    unless appointment
      Rails.logger.warn "[WA JOB] No se encontró appointment_id=#{appointment_id}"
      return
    end

    if appointment.canceled_by_admin? || appointment.canceled_by_client? || appointment.no_show?
      Rails.logger.info "[WA JOB] Cita cancelada o inválida para enviar recordatorio appointment_id=#{appointment_id} status=#{appointment.status}"
      return
    end

    service = WhatsappNotificationService.new
    pdf_url = appointment_pdf_url(appointment)

    case message_type.to_s
    when "confirmation"
      send_confirmation_message(service: service, to: to, appointment: appointment, pdf_url: pdf_url)

    when "reminder_24h"
      send_reminder_24h(service: service, to: to, appointment: appointment)

    when "reminder_2h"
      send_reminder_2h(service: service, to: to, appointment: appointment)

    else
      Rails.logger.error "[WA JOB] Tipo de mensaje desconocido: #{message_type}"
    end
  rescue => e
    Rails.logger.error "[WA JOB] Error #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    raise
  end

  private

  def send_confirmation_message(service:, to:, appointment:, pdf_url:)
    body = <<~MSG.strip
      ✅ *¡Tu cita ha sido agendada con éxito!*

      👤 *Paciente:* #{appointment.name}
      📅 *Fecha:* #{I18n.l(appointment.start_date.to_date, format: :long, locale: :es)}
      🕐 *Hora:* #{appointment.start_date.strftime("%H:%M")}
      🏥 *Tipo de cita / estudio:* #{appointment.package&.name || "Cita médica"}
      👨‍⚕️ *Atención con:* #{appointment.doctor&.name || "Personal médico"}
      🔑 *Código de cita:* #{appointment.unique_code}

      📄 *Comprobante de tu cita:* #{pdf_url}

      ⚠️ *Indicaciones importantes:*
      • Preséntate con algunos minutos de anticipación.
      • Conserva tu código de cita para cualquier aclaración.
      • Si tu cita requiere preparación previa, sigue las indicaciones que te hayan compartido.

      ❌ *Cancelaciones o cambios:*
      Si no podrás asistir o necesitas reagendar, por favor hazlo con anticipación para liberar el espacio y poder ayudarte mejor.

      🔕 *Aviso importante:*
      Este número es solo para *notificaciones automáticas*. No recibe llamadas ni mensajes.

      🙌 Gracias por confiar en nosotros.
    MSG

    result = service.send_text(to: to, body: body)
    Rails.logger.info "[WA JOB] confirmation result=#{result.inspect} appointment_id=#{appointment.id}"
  end

  def send_reminder_24h(service:, to:, appointment:)
    body = <<~MSG.strip
      🔔 *Recordatorio de cita*

      Hola, #{appointment.name}. Te recordamos que tienes una cita programada.

      📅 *Fecha:* #{I18n.l(appointment.start_date.to_date, format: :long, locale: :es)}
      🕐 *Hora:* #{appointment.start_date.strftime("%H:%M")}
      🏥 *Tipo de cita / estudio:* #{appointment.package&.name || "Cita médica"}
      👨‍⚕️ *Atención con:* #{appointment.doctor&.name || "Personal médico"}
      🔑 *Código de cita:* #{appointment.unique_code}

      ⏰ Te recomendamos llegar con algunos minutos de anticipación.

      ❌ Si necesitas cancelar o reagendar, por favor hazlo con anticipación.

      🔕 *Aviso importante:*
      Este número es solo para *notificaciones automáticas*. No recibe llamadas ni mensajes.
    MSG

    result = service.send_text(to: to, body: body)
    Rails.logger.info "[WA JOB] reminder_24h result=#{result.inspect} appointment_id=#{appointment.id}"
  end

  def send_reminder_2h(service:, to:, appointment:)
    body = <<~MSG.strip
      ⏰ *Tu cita es en aproximadamente 2 horas*

      Hola, #{appointment.name}. Este es un recordatorio final de tu cita.

      📅 *Fecha:* #{I18n.l(appointment.start_date.to_date, format: :long, locale: :es)}
      🕐 *Hora:* #{appointment.start_date.strftime("%H:%M")}
      🏥 *Tipo de cita / estudio:* #{appointment.package&.name || "Cita médica"}
      👨‍⚕️ *Atención con:* #{appointment.doctor&.name || "Personal médico"}
      🔑 *Código de cita:* #{appointment.unique_code}

      📍 Si aún no sales, te recomendamos prepararte con tiempo para llegar puntual.

      🔕 *Aviso importante:*
      Este número es solo para *notificaciones automáticas*. No recibe llamadas ni mensajes.
    MSG

    result = service.send_text(to: to, body: body)
    Rails.logger.info "[WA JOB] reminder_2h result=#{result.inspect} appointment_id=#{appointment.id}"
  end

  def appointment_pdf_url(appointment)
    Rails.application.routes.url_helpers.appointment_url(
      appointment,
      format: :pdf
    )
  end
end
