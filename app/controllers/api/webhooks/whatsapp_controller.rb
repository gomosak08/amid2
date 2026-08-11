# app/controllers/api/webhooks/whatsapp_controller.rb

module Api
  module Webhooks
    class WhatsappController < ActionController::API

      def verify
        if params["hub.verify_token"] == ENV["WHATSAPP_VERIFY_TOKEN"]
          render plain: params["hub.challenge"]
        else
          head :forbidden
        end
      end

      def receive
        payload = request.raw_post

        Rails.logger.info "WHATSAPP WEBHOOK"
        Rails.logger.info payload

        data = JSON.parse(payload)

        process_messages(data)

        head :ok
      rescue => e
        Rails.logger.error e.message
        Rails.logger.error e.backtrace.join("\n")

        head :ok
      end

      private

      def process_messages(data)

        entries = data["entry"] || []

        entries.each do |entry|
          (entry["changes"] || []).each do |change|

            value = change["value"]

            next unless value

            (value["messages"] || []).each do |message|

              from = message["from"]
              type = message["type"]

              case type

              when "text"

                body = message.dig("text", "body")

                Rails.logger.info "Mensaje de #{from}: #{body}"

                # Aquí puedes buscar una cita por teléfono
                # appointment = Appointment.find_by(phone_number_e164: from)

                # o guardar el mensaje en BD

              when "image"

                image_id = message.dig("image", "id")

              when "document"

                document_id = message.dig("document", "id")

              end

            end
          end
        end
      end
    end
  end
end