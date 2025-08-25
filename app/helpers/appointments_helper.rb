module AppointmentsHelper
  def human_status(appointment)
    key = appointment.status.to_s
    I18n.t("activerecord.attributes.appointment.status.#{key}")
  end
end
