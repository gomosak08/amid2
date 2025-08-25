# app/services/url_builders/appointment_urls.rb
# frozen_string_literal: true

module UrlBuilders
  class AppointmentUrls
    def self.edit(host:, token:)
      host = host.to_s
      host = "https://#{host}" unless host.start_with?("http://", "https://")
      "#{host}/appointments/#{token}/edit"
    end
  end
end
