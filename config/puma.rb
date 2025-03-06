threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
threads threads_count, threads_count

# Use Unix socket for Nginx integration
#bind "unix:///var/www/your_app/shared/sockets/puma.sock"
bind "tcp://127.0.0.1:3000"

# Alternatively, use TCP port (for debugging or non-Nginx setups)
# port ENV.fetch("PORT") { 3000 }

environment ENV.fetch("RAILS_ENV") { "production" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

preload_app!

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Logging (Optional)
#stdout_redirect "log/puma.stdout.log", "log/puma.stderr.log", true
