module AppointmentsHelper
  def human_status(obj)
    key =
      if obj.respond_to?(:status)
        obj.status.to_s
      else
        obj.to_s
      end

    key = "scheduled" if key.blank?

    I18n.t("activerecord.attributes.appointment.statuses.#{key}",
           default: key.humanize)
  end
end
