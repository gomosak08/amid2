require 'webrick'

server = WEBrick::HTTPServer.new(Port: 4567)

authorization_code = nil

server.mount_proc '/callback' do |req, res|
  authorization_code = req.query['code']
  puts "Authorization code received: #{authorization_code}"
  res.body = 'Authorization successful! You can close this window.'
  server.shutdown
end

puts "Server running at http://localhost:4567/callback"
server.start

puts "Authorization code: #{authorization_code}" if authorization_code
