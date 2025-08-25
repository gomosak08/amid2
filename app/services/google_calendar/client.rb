# frozen_string_literal: true

# Requiere:
# gem "google-apis-calendar_v3"
# gem "signet"
module GoogleCalendar
  class Client
    def self.build
      require "google/apis/calendar_v3"
      require "signet/oauth_2/client"

      service = Google::Apis::CalendarV3::CalendarService.new

      client_id     = Rails.application.credentials.dig(:google, :client_id)     || ENV["GOOGLE_CLIENT_ID"]
      client_secret = Rails.application.credentials.dig(:google, :client_secret) || ENV["GOOGLE_CLIENT_SECRET"]
      refresh_token = Rails.application.credentials.dig(:google, :refresh_token) || ENV["GOOGLE_REFRESH_TOKEN"]

      raise "Google Calendar credentials missing" if [ client_id, client_secret, refresh_token ].any?(&:blank?)

      auth = Signet::OAuth2::Client.new(
        client_id: client_id,
        client_secret: client_secret,
        token_credential_uri: "https://oauth2.googleapis.com/token",
        refresh_token: refresh_token,
        scope: "https://www.googleapis.com/auth/calendar"
      )

      # Obtiene y asigna access_token
      auth.fetch_access_token!
      service.authorization = auth
      service
    end
  end
end
