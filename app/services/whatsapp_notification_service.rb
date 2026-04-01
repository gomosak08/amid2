require "net/http"
require "uri"
require "json"

class WhatsappNotificationService
  META_API_VERSION = "v22.0".freeze

  def initialize
    @access_token = ENV.fetch("WHATSAPP_ACCESS_TOKEN", nil)
    @phone_number_id = ENV.fetch("WHATSAPP_PHONE_NUMBER_ID", nil)
  end

  def send_text(to:, body:)
    return false unless valid_credentials?

    payload = {
      messaging_product: "whatsapp",
      to: format_phone(to),
      type: "text",
      text: {
        body: body
      }
    }

    send_request(payload)
  end

  def send_template(to:, template_name:, language_code: "es_MX", parameters: [])
    return false unless valid_credentials?

    payload = {
      messaging_product: "whatsapp",
      to: format_phone(to),
      type: "template",
      template: {
        name: template_name,
        language: {
          code: language_code
        }
      }
    }

    if parameters.any?
      payload[:template][:components] = [
        {
          type: "body",
          parameters: parameters
        }
      ]
    end

    send_request(payload)
  end

  private

  def send_request(payload)
    uri = URI("https://graph.facebook.com/#{META_API_VERSION}/#{@phone_number_id}/messages")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@access_token}"
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    result = JSON.parse(response.body) rescue { raw_body: response.body }

    Rails.logger.info "[WA SERVICE] STATUS=#{response.code}"
    Rails.logger.info "[WA SERVICE] PAYLOAD=#{payload.inspect}"
    Rails.logger.info "[WA SERVICE] RESPONSE=#{result.inspect}"

    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.info "[WA SERVICE] WhatsApp enviado correctamente a #{payload[:to]}"
      true
    else
      Rails.logger.error "[WA SERVICE] Fallo al enviar WhatsApp a #{payload[:to]}. Error: #{result.inspect}"
      false
    end
  rescue => e
    Rails.logger.error "[WA SERVICE] Excepción #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    false
  end

  def format_phone(phone)
    phone.to_s.gsub(/[^0-9]/, "")
  end

  def valid_credentials?
    if @access_token.blank? || @phone_number_id.blank?
      Rails.logger.warn "[WA SERVICE] Credentials missing: revisa WHATSAPP_ACCESS_TOKEN y WHATSAPP_PHONE_NUMBER_ID"
      return false
    end

    true
  end
end
