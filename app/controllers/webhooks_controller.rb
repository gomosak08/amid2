# app/controllers/webhooks_controller.rb
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  # 🔐 Verificación inicial de Meta
  def verify
    if params["hub.verify_token"] == ENV["WHATSAPP_VERIFY_TOKEN"]
      render plain: params["hub.challenge"]
    else
      render plain: "Error", status: 403
    end
  end

  # 📩 Recepción de eventos
  def whatsapp
    Rails.logger.info "[WA WEBHOOK] Payload: #{params.to_unsafe_h}"

    entry = params["entry"]&.first
    changes = entry&.dig("changes")&.first
    value = changes&.dig("value")

    statuses = value&.dig("statuses")

    if statuses
      statuses.each do |status|
        Rails.logger.info "[WA STATUS] #{status}"

        # Ejemplo:
        # status["status"] => sent, delivered, read, failed
        # status["id"] => wamid...
      end
    end

    head :ok
  end
end
