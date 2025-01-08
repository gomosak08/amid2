# google_oauth_authorization.rb
require 'googleauth'
require 'signet/oauth_2/client'

# Directly specify client_id and client_secret here
GOOGLE_CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
GOOGLE_CLIENT_SECRET = ENV['GOOGLE_CLIENT_SECRET']



client = Signet::OAuth2::Client.new(
  client_id: client_id,
  client_secret: client_secret,
  token_credential_uri: 'https://oauth2.googleapis.com/token',
  authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
  scope: 'https://www.googleapis.com/auth/calendar',
  redirect_uri: 'http://localhost' # or whatever you have set in Google Console
)
# Generate the authorization URL and display it
auth_url = client.authorization_uri.to_s
puts "Open the following URL in your browser and authorize the application:\n\n#{auth_url}\n\n"

# After authorizing, Google will provide a code. Paste it below
print 'Enter the authorization code provided by Google: '
code = gets.chomp

# Exchange the authorization code for an access token and refresh token
client.code = code
client.fetch_access_token!

# Output the tokens
puts "\nAccess Token: #{client.access_token}"
puts "Refresh Token: #{client.refresh_token}"

#https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=366581620056-emqqfjma7c8uu5mfl3b79e3j6au7bvl5.apps.googleusercontent.com&redirect_uri=http://localhost:3000&response_type=code&scope=https://www.googleapis.com/auth/calendar
#https://accounts.google.com/o/oauth2/auth?access_type=offline&client_id=%22366581620056-emqqfjma7c8uu5mfl3b79e3j6au7bvl5.apps.googleusercontent.com%22&redirect_uri=http://localhost:3000&response_type=code&scope=https://www.googleapis.com/auth/calendar