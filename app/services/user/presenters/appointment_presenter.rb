# app/services/presenters/appointment_presenter.rb
# frozen_string_literal: true

module User::Presenters
  class AppointmentPresenter
    def initialize(appointment)
      @a = appointment
    end

    def status_text
      # TODO: usar I18n para traducir @a.status
      @a.status.to_s
    end

    def status_color_hex
      # TODO: devolver color HEX según status
      "3A86FF"
    end

    def formatted_start_time
      # TODO: formatear fecha/hora (I18n.l con zona)
      @a.start_date&.to_s
    end
  end
end
