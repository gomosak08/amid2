require "googleauth"
require "signet/oauth_2/client"
require "dotenv/load"
require "yaml"

class GoogleOauthAuthorization
  ENV["SSL_CERT_FILE"] = "/etc/ssl/certs/cacert.pem"

  # Define the path to save the tokens
  TOKEN_FILE = "config/google_tokens.yaml"

  def self.authorize
    client = Signet::OAuth2::Client.new(
      client_id: ENV["CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      scope: "https://www.googleapis.com/auth/calendar",
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"] || "http://localhost:4567/callback"
    )

    # Load tokens if they exist
    if File.exist?(TOKEN_FILE)
      puts "Loading saved tokens from #{TOKEN_FILE}..."
      tokens = YAML.load_file(TOKEN_FILE)
      client.access_token = tokens["access_token"]
      client.refresh_token = tokens["refresh_token"]
    else
      raise "Authorization required. Run `GoogleOauthAuthorization.start_auth_flow` to authorize."
    end

    # Refresh the token if it's expired
    if client.expired?
      puts "Refreshing access token..."
      client.fetch_access_token!
      tokens = {
        "access_token" => client.access_token,
        "refresh_token" => client.refresh_token
      }
      File.write(TOKEN_FILE, tokens.to_yaml)
      puts "Access token refreshed and saved."
    end

    client
  end

  # Method to initiate the authorization flow
  def self.start_auth_flow
    client = Signet::OAuth2::Client.new(
      client_id: ENV["CLIENT_ID"],
      client_secret: ENV["GOOGLE_CLIENT_SECRET"],
      token_credential_uri: "https://oauth2.googleapis.com/token",
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      scope: "https://www.googleapis.com/auth/calendar",
      redirect_uri: ENV["GOOGLE_REDIRECT_URI"] || "http://localhost:4567/callback"
    )

    # Display the authorization URL
    auth_url = client.authorization_uri.to_s
    puts "Open the following URL in your browser and authorize the application:\n\n#{auth_url}\n\n"

    # Prompt for the code in an interactive environment
    print "Enter the authorization code provided by Google: "
    code = gets.chomp

    # Exchange the code for tokens
    client.code = code
    client.fetch_access_token!

    # Save the tokens for future use
    tokens = {
      "access_token" => client.access_token,
      "refresh_token" => client.refresh_token
    }
    File.write(TOKEN_FILE, tokens.to_yaml)
    puts "Tokens saved to #{TOKEN_FILE}."
  end
end
