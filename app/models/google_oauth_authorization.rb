require 'googleauth'
require 'signet/oauth_2/client'
require 'dotenv/load'
require 'yaml'

class GoogleOauthAuthorization
  ENV['SSL_CERT_FILE'] = '/etc/ssl/certs/cacert.pem'

  # Define the path to save the tokens
  TOKEN_FILE = 'config/google_tokens.yaml'

  def self.authorize
    # Create a Signet OAuth2 client
    client = Signet::OAuth2::Client.new(
      client_id: ENV['CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      token_credential_uri: 'https://oauth2.googleapis.com/token',
      authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
      scope: 'https://www.googleapis.com/auth/calendar',
      redirect_uri: 'http://localhost:4567/callback', # Replace with your actual redirect URI
      additional_parameters: { 'access_type' => 'offline', 'prompt' => 'consent' }
    )

    tokens = {}

    # Check if token file exists and load tokens
    if File.exist?(TOKEN_FILE)
      puts "Loading saved tokens from #{TOKEN_FILE}..."
      tokens = YAML.load_file(TOKEN_FILE)
      client.access_token = tokens['access_token']
      client.refresh_token = tokens['refresh_token']
    end

    # If the refresh_token is missing, request authorization
    if client.refresh_token.nil? || client.refresh_token.empty?
      puts "Missing refresh token. You need to reauthorize the application."

      # Generate the authorization URL and display it
      auth_url = client.authorization_uri.to_s
      puts "Open the following URL in your browser and authorize the application:\n\n#{auth_url}\n\n"

      # After authorizing, Google will provide a code. Paste it below
      print 'Enter the authorization code provided by Google: '
      code = gets.chomp

      # Exchange the authorization code for an access token and refresh token
      client.code = code
      client.fetch_access_token!

      tokens['access_token'] = client.access_token
      tokens['refresh_token'] = client.refresh_token

      # Save tokens to a file for future use
      File.write(TOKEN_FILE, tokens.to_yaml)
      puts "Tokens saved to #{TOKEN_FILE}."
    end

    # Refresh the token if it's expired
    if client.expired?
      puts "Refreshing access token..."
      client.fetch_access_token!
      # Update the token file
      tokens['access_token'] = client.access_token
      File.write(TOKEN_FILE, tokens.to_yaml)
      puts "Access token refreshed and saved."
    end

    client
  end
end

# Usage
client = GoogleOauthAuthorization.authorize
puts "Access Token: #{client.access_token}"
puts "Refresh Token: #{client.refresh_token}"
